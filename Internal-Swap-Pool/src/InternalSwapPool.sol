// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SwapMath} from "@uniswap/v4-core/src/libraries/SwapMath.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary, toBeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {CurrencySettler} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";

/**
 * @title InternalSwapPool
 * @author Allan Robinson
 * @notice Custom Pricing Curve Hook - Internal Swap Pool for UHI Week 3 Homework
 * @dev This hook implements an internal swap pool that:
 *      1. Routes all fees to a single token (Currency0/ETH)
 *      2. Creates an internal orderbook to fill swaps before hitting Uniswap
 *      3. Distributes fees to LPs without selling pressure on TOKEN
 *      4. Perfect for token launchpads and fair launch mechanisms
 *
 * When fees are collected, they are distributed between the Uniswap V4 pool
 * to promote liquidity via the donate mechanism.
 *
 * The hook uses beforeSwapReturnDelta to implement custom pricing logic that
 * fills swaps from internal reserves before hitting the main AMM pool.
 */
contract InternalSwapPool is BaseHook {
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    /// @notice Minimum threshold for donations to prevent gas waste
    uint256 public constant DONATE_THRESHOLD_MIN = 0.0001 ether;

    /// @notice Fee percentage taken from swaps (1% = 100 basis points)
    uint256 public constant FEE_BPS = 100;
    uint256 public constant BPS_DENOMINATOR = 10000;

    /// @notice The native token address (ETH/WETH)
    address public immutable nativeToken;

    /**
     * @notice Internal fee tracking per pool
     * @param amount0 The amount of currency0 (ETH) available to distribute
     * @param amount1 The amount of currency1 (TOKEN) available to distribute
     */
    struct ClaimableFees {
        uint256 amount0;
        uint256 amount1;
    }

    /// @notice Maps PoolId to claimable fees
    mapping(PoolId => ClaimableFees) internal _poolFees;

    /// @notice Emitted when fees are deposited into the hook
    event FeesDeposited(PoolId indexed poolId, uint256 amount0, uint256 amount1);

    /// @notice Emitted when fees are distributed to LPs
    event FeesDistributed(PoolId indexed poolId, uint256 amount0);

    /// @notice Emitted when internal swap occurs
    event InternalSwapExecuted(
        PoolId indexed poolId,
        uint256 tokenIn,
        uint256 ethOut,
        address indexed user
    );

    /**
     * @notice Constructor to set up the hook
     * @param _poolManager The Uniswap V4 PoolManager address
     * @param _nativeToken The native token address (WETH)
     */
    constructor(address _poolManager, address _nativeToken)
        BaseHook(IPoolManager(_poolManager))
    {
        nativeToken = _nativeToken;
    }

    /**
     * @notice Returns the hook permissions required
     * @return Hooks.Permissions struct with required permissions
     */
    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,                       // Fill internal swaps
            afterSwap: true,                        // Capture fees
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: true,            // Custom pricing
            afterSwapReturnDelta: true,             // Fee extraction
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /**
     * @notice Get current claimable fees for a pool
     * @param _poolKey The PoolKey of the pool
     * @return The ClaimableFees struct for the pool
     */
    function poolFees(PoolKey calldata _poolKey)
        public
        view
        returns (ClaimableFees memory)
    {
        return _poolFees[_poolKey.toId()];
    }

    /**
     * @notice Deposits fees into the hook's internal accounting
     * @param _poolKey The PoolKey of the pool
     * @param _amount0 The amount of currency0 to deposit
     * @param _amount1 The amount of currency1 to deposit
     */
    function depositFees(
        PoolKey calldata _poolKey,
        uint256 _amount0,
        uint256 _amount1
    ) public {
        PoolId poolId = _poolKey.toId();
        _poolFees[poolId].amount0 += _amount0;
        _poolFees[poolId].amount1 += _amount1;

        emit FeesDeposited(poolId, _amount0, _amount1);
    }

    /**
     * @notice Hook called before a swap executes
     * @dev Attempts to fill swap from internal TOKEN reserves before hitting Uniswap pool
     * @param sender The address initiating the swap
     * @param key The pool key
     * @param params The swap parameters
     * @return selector_ The function selector
     * @return beforeSwapDelta_ The delta to apply before the swap
     * @return swapFee_ The LP fee (unused, returns 0)
     */
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata /* hookData */
    )
        external
        override
        onlyPoolManager
        returns (bytes4 selector_, BeforeSwapDelta beforeSwapDelta_, uint24 swapFee_)
    {
        PoolId poolId = key.toId();

        // Only process if:
        // 1. Swapping TOKEN for ETH (zeroForOne = false, i.e., token1 → token0)
        // 2. We have TOKEN fees stored in the hook
        if (!params.zeroForOne && _poolFees[poolId].amount1 != 0) {
            uint256 tokenIn;
            uint256 ethOut;

            // Get current pool price
            (uint160 sqrtPriceX96, , , ) = poolManager.getSlot0(poolId);

            // Handle based on exact input vs exact output
            if (params.amountSpecified >= 0) {
                // EXACT OUTPUT: User wants specific amount of ETH
                (tokenIn, ethOut) = _handleExactOutput(
                    poolId,
                    key,
                    params,
                    sqrtPriceX96
                );

                // Return BeforeSwapDelta
                // Specified = ETH (what user wants)
                // Unspecified = TOKEN (what user will pay)
                beforeSwapDelta_ = toBeforeSwapDelta(
                    -int128(int256(tokenIn)),  // Hook takes TOKEN
                    int128(int256(ethOut))     // Hook gives ETH
                );
            } else {
                // EXACT INPUT: User selling specific amount of TOKEN
                (tokenIn, ethOut) = _handleExactInput(
                    poolId,
                    params,
                    sqrtPriceX96
                );

                // Return BeforeSwapDelta
                // Specified = TOKEN (what user is selling)
                // Unspecified = ETH (what user will receive)
                beforeSwapDelta_ = toBeforeSwapDelta(
                    int128(int256(ethOut)),     // Hook gives ETH
                    -int128(int256(tokenIn))    // Hook takes TOKEN
                );
            }

            // Update internal fee reserves
            _poolFees[poolId].amount0 += ethOut;    // Gained ETH
            _poolFees[poolId].amount1 -= tokenIn;   // Spent TOKEN

            // Sync balances with PoolManager
            poolManager.sync(key.currency0);
            poolManager.sync(key.currency1);

            // Transfer tokens
            // Give ETH from PoolManager to hook
            poolManager.take(key.currency0, address(this), ethOut);
            // Take TOKEN from hook and send to PoolManager
            key.currency1.settle(poolManager, address(this), tokenIn, false);

            emit InternalSwapExecuted(poolId, tokenIn, ethOut, sender);
        }

        selector_ = IHooks.beforeSwap.selector;
        swapFee_ = 0;
    }

    /**
     * @notice Handles exact output swaps (user specifies ETH to receive)
     * @param poolId The pool ID
     * @param key The pool key
     * @param params The swap parameters
     * @param sqrtPriceX96 Current pool price
     * @return tokenIn Amount of TOKEN to take from user
     * @return ethOut Amount of ETH to give to user
     */
    function _handleExactOutput(
        PoolId poolId,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        uint160 sqrtPriceX96
    ) internal view returns (uint256 tokenIn, uint256 ethOut) {
        // User wants X amount of ETH
        // We can provide min(X, available_token_fees_worth)
        uint256 amountSpecified = uint256(params.amountSpecified) > _poolFees[poolId].amount1
            ? _poolFees[poolId].amount1
            : uint256(params.amountSpecified);

        // Use SwapMath to calculate amounts at current price
        // No fee (feePips = 0) because we're helping the ecosystem
        (, ethOut, tokenIn, ) = SwapMath.computeSwapStep({
            sqrtPriceCurrentX96: sqrtPriceX96,
            sqrtPriceTargetX96: params.sqrtPriceLimitX96,
            liquidity: poolManager.getLiquidity(poolId),
            amountRemaining: int256(amountSpecified),
            feePips: 0
        });
    }

    /**
     * @notice Handles exact input swaps (user specifies TOKEN to sell)
     * @param poolId The pool ID
     * @param params The swap parameters
     * @param sqrtPriceX96 Current pool price
     * @return tokenIn Amount of TOKEN to take from user
     * @return ethOut Amount of ETH to give to user
     */
    function _handleExactInput(
        PoolId poolId,
        IPoolManager.SwapParams calldata params,
        uint160 sqrtPriceX96
    ) internal view returns (uint256 tokenIn, uint256 ethOut) {
        // User is selling X TOKEN
        // Calculate how much ETH all our TOKEN fees are worth
        (, ethOut, tokenIn, ) = SwapMath.computeSwapStep({
            sqrtPriceCurrentX96: sqrtPriceX96,
            sqrtPriceTargetX96: params.sqrtPriceLimitX96,
            liquidity: poolManager.getLiquidity(poolId),
            amountRemaining: int256(_poolFees[poolId].amount1),
            feePips: 0
        });

        // Check if user's input is enough to use all our fees
        if (ethOut > uint256(-params.amountSpecified)) {
            // User input < our available fees
            // Scale down proportionally
            uint256 percentage = (uint256(-params.amountSpecified) * 1e18) / ethOut;
            tokenIn = (tokenIn * percentage) / 1e18;
            ethOut = uint256(-params.amountSpecified);
        }
    }

    /**
     * @notice Hook called after a swap executes
     * @dev Captures fees and distributes to LPs
     * @param sender The address that initiated the swap
     * @param key The pool key
     * @param params The swap parameters
     * @param delta The balance delta from the swap
     * @return selector_ The function selector
     * @return hookDeltaUnspecified_ The amount to extract as fees
     */
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata /* hookData */
    )
        external
        override
        onlyPoolManager
        returns (bytes4 selector_, int128 hookDeltaUnspecified_)
    {
        // Determine which currency is the unspecified one (the output)
        Currency swapFeeCurrency = params.amountSpecified < 0 == params.zeroForOne
            ? key.currency1
            : key.currency0;

        // Get the unspecified amount (what user received)
        int128 swapAmount = params.amountSpecified < 0 == params.zeroForOne
            ? delta.amount1()
            : delta.amount0();

        // Calculate fee (1% of output)
        uint256 absSwapAmount = swapAmount < 0
            ? uint256(uint128(-swapAmount))
            : uint256(uint128(swapAmount));
        uint256 swapFee = (absSwapAmount * FEE_BPS) / BPS_DENOMINATOR;

        // Store fees internally
        if (params.zeroForOne) {
            // Swapping token0 → token1, fee is in token1
            _poolFees[key.toId()].amount1 += swapFee;
        } else {
            // Swapping token1 → token0, fee is in token0
            _poolFees[key.toId()].amount0 += swapFee;
        }

        // Take the fee from the swap output
        // Positive delta means: hook took currency (reduces user's output by this amount)
        hookDeltaUnspecified_ = int128(int256(swapFee));

        // Actually take the tokens to settle the debt created by the positive delta
        swapFeeCurrency.take(poolManager, address(this), swapFee, false);

        // Distribute accumulated ETH fees to LPs
        _distributeFees(key);

        selector_ = IHooks.afterSwap.selector;
    }

    /**
     * @notice Distributes accumulated ETH fees to LPs via donate
     * @param _poolKey The pool key
     */
    function _distributeFees(PoolKey calldata _poolKey) internal {
        PoolId poolId = _poolKey.toId();
        uint256 donateAmount = _poolFees[poolId].amount0;

        // Only donate if above minimum threshold
        if (donateAmount < DONATE_THRESHOLD_MIN) {
            return;
        }

        // Tokens are already in the hook contract (taken in afterSwap)
        // Donate to LPs (all in token0/ETH)
        BalanceDelta delta = poolManager.donate(_poolKey, donateAmount, 0, "");

        // Settle the donation (we owe ETH to PoolManager)
        if (delta.amount0() < 0) {
            _poolKey.currency0.settle(
                poolManager,
                address(this),
                uint256(uint128(-delta.amount0())),
                false
            );
        }

        // Reduce our tracked fees
        _poolFees[poolId].amount0 -= donateAmount;

        emit FeesDistributed(poolId, donateAmount);
    }
}
