// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {ERC1155} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {IERC20} from "v4-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title LimitOrder
 * @notice Hook that enables limit orders on Uniswap v4 pools
 * @dev Users place limit orders at specific ticks. When price crosses that tick,
 *      orders are executed automatically. Users receive ERC-1155 claim tokens
 *      that can be redeemed for output tokens after execution.
 */
contract LimitOrder is BaseHook, ERC1155 {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;
    using CurrencyLibrary for Currency;

    // ========== STRUCTS ==========

    /**
     * @notice Represents a limit order
     * @param owner Address that placed the order
     * @param tick Tick at which the order should execute
     * @param amount Amount of input tokens
     * @param zeroForOne Direction of swap (true = token0 -> token1)
     * @param executed Whether the order has been executed
     */
    struct Order {
        address owner;
        int24 tick;
        uint256 amount;
        bool zeroForOne;
        bool executed;
    }

    // ========== CONSTANTS ==========

    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;

    // ========== STATE VARIABLES ==========

    /// @notice Mapping from order ID to Order struct
    mapping(uint256 => Order) public orders;

    /// @notice Counter for generating unique order IDs
    uint256 public nextOrderId;

    /// @notice Mapping from pool ID and tick to count of orders at that tick
    mapping(PoolId => mapping(int24 => uint256)) public orderCounts;

    /// @notice Mapping from pool ID to last tick (for tracking tick crossings)
    mapping(PoolId => int24) public lastTicks;

    /// @notice Mapping from order ID to claimable output tokens
    mapping(uint256 => uint256) public claimableOutputTokens;

    // ========== EVENTS ==========

    event OrderPlaced(
        uint256 indexed orderId,
        address indexed owner,
        PoolId indexed poolId,
        int24 tick,
        uint256 amount,
        bool zeroForOne
    );

    event OrderCancelled(uint256 indexed orderId, address indexed owner);

    event OrderExecuted(
        uint256 indexed orderId,
        PoolId indexed poolId,
        uint256 amountIn,
        uint256 amountOut
    );

    event TokensRedeemed(
        uint256 indexed orderId,
        address indexed user,
        uint256 amount
    );

    // ========== ERRORS ==========

    error NotOrderOwner();
    error OrderAlreadyExecuted();
    error OrderNotExecuted();
    error InsufficientClaimBalance();
    error RecursiveSwapNotAllowed();

    // ========== CONSTRUCTOR ==========

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) ERC1155("") {}

    // ========== HOOK PERMISSIONS ==========

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: true,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    // ========== HOOK CALLBACKS ==========

    /**
     * @notice After pool initialization, store the initial tick
     */
    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160,
        int24 tick,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4) {
        PoolId poolId = key.toId();
        lastTicks[poolId] = tick;
        return BaseHook.afterInitialize.selector;
    }

    /**
     * @notice After each swap, check for tick crossings and execute orders
     */
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4, int128) {
        // Prevent recursive swaps (when hook itself is swapping)
        if (sender == address(this)) {
            return (BaseHook.afterSwap.selector, 0);
        }

        PoolId poolId = key.toId();

        // Get current tick after the swap
        (, int24 currentTick, , ) = poolManager.getSlot0(poolId);
        int24 prevTick = lastTicks[poolId];

        // Determine the range of ticks crossed
        int24 lower;
        int24 upper;

        if (params.zeroForOne) {
            // Price decreased (tick decreased)
            lower = currentTick;
            upper = prevTick;
        } else {
            // Price increased (tick increased)
            lower = prevTick;
            upper = currentTick;
        }

        // Try executing orders in the crossed tick range
        if (lower != upper) {
            tryExecutingOrders(key, lower, upper, params.zeroForOne);
        }

        // Update last tick
        lastTicks[poolId] = currentTick;

        return (BaseHook.afterSwap.selector, 0);
    }

    // ========== ORDER MANAGEMENT ==========

    /**
     * @notice Place a limit order at a specific tick
     * @param key Pool key
     * @param tick Target tick for order execution
     * @param amount Amount of input tokens
     * @param zeroForOne Direction of swap
     * @return orderId Unique identifier for the order
     */
    function placeOrder(
        PoolKey calldata key,
        int24 tick,
        uint256 amount,
        bool zeroForOne
    ) external returns (uint256 orderId) {
        orderId = nextOrderId++;

        orders[orderId] = Order({
            owner: msg.sender,
            tick: tick,
            amount: amount,
            zeroForOne: zeroForOne,
            executed: false
        });

        PoolId poolId = key.toId();
        orderCounts[poolId][tick]++;

        // Transfer input tokens from user to hook
        Currency inputCurrency = zeroForOne ? key.currency0 : key.currency1;
        IERC20(Currency.unwrap(inputCurrency)).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        // Mint ERC-1155 claim token to user
        _mint(msg.sender, orderId, amount, "");

        emit OrderPlaced(orderId, msg.sender, poolId, tick, amount, zeroForOne);
    }

    /**
     * @notice Cancel a pending limit order
     * @param orderId ID of the order to cancel
     * @param key Pool key (needed to get currency)
     */
    function cancelOrder(uint256 orderId, PoolKey calldata key) external {
        Order storage order = orders[orderId];

        if (order.owner != msg.sender) revert NotOrderOwner();
        if (order.executed) revert OrderAlreadyExecuted();

        // Burn claim tokens
        _burn(msg.sender, orderId, order.amount);

        // Return input tokens to user
        Currency inputCurrency = order.zeroForOne ? key.currency0 : key.currency1;
        IERC20(Currency.unwrap(inputCurrency)).transfer(msg.sender, order.amount);

        // Mark as executed (cancelled)
        order.executed = true;

        PoolId poolId = key.toId();
        orderCounts[poolId][order.tick]--;

        emit OrderCancelled(orderId, msg.sender);
    }

    /**
     * @notice Redeem claim tokens for output tokens after order execution
     * @param orderId ID of the executed order
     * @param amount Amount of claim tokens to redeem
     * @param key Pool key (needed to get currency)
     */
    function redeem(
        uint256 orderId,
        uint256 amount,
        PoolKey calldata key
    ) external {
        Order storage order = orders[orderId];

        if (!order.executed) revert OrderNotExecuted();
        if (balanceOf(msg.sender, orderId) < amount) revert InsufficientClaimBalance();

        // Burn claim tokens
        _burn(msg.sender, orderId, amount);

        // Calculate proportional output tokens
        uint256 totalClaimable = claimableOutputTokens[orderId];
        uint256 userShare = (totalClaimable * amount) / order.amount;

        // Transfer output tokens to user
        Currency outputCurrency = order.zeroForOne ? key.currency1 : key.currency0;
        IERC20(Currency.unwrap(outputCurrency)).transfer(msg.sender, userShare);

        emit TokensRedeemed(orderId, msg.sender, userShare);
    }

    // ========== INTERNAL FUNCTIONS ==========

    /**
     * @notice Try executing orders in a tick range
     * @dev Iterates through ticks and executes orders at each tick
     */
    function tryExecutingOrders(
        PoolKey calldata key,
        int24 lowerTick,
        int24 upperTick,
        bool zeroForOne
    ) internal {
        PoolId poolId = key.toId();

        // Iterate through crossed ticks
        for (int24 tick = lowerTick; tick <= upperTick; tick++) {
            uint256 count = orderCounts[poolId][tick];
            if (count == 0) continue;

            // Find and execute orders at this tick
            for (uint256 i = 0; i < nextOrderId; i++) {
                Order storage order = orders[i];

                // Check if order matches criteria
                if (
                    order.tick == tick &&
                    !order.executed &&
                    order.zeroForOne == zeroForOne
                ) {
                    executeOrder(i, key);
                }
            }
        }
    }

    /**
     * @notice Execute a single limit order
     * @dev Swaps the input tokens and stores claimable output
     */
    function executeOrder(uint256 orderId, PoolKey calldata key) internal {
        Order storage order = orders[orderId];

        if (order.executed) return;

        // Mark as executed immediately to prevent reentrancy
        order.executed = true;

        // Approve tokens for PoolManager
        Currency inputCurrency = order.zeroForOne ? key.currency0 : key.currency1;
        IERC20(Currency.unwrap(inputCurrency)).approve(
            address(poolManager),
            order.amount
        );

        // Execute swap through PoolManager
        try
            poolManager.unlock(
                abi.encode(
                    UnlockData({
                        orderId: orderId,
                        key: key,
                        zeroForOne: order.zeroForOne,
                        amountIn: order.amount
                    })
                )
            )
        returns (bytes memory returnData) {
            uint256 amountOut = abi.decode(returnData, (uint256));
            claimableOutputTokens[orderId] = amountOut;

            PoolId poolId = key.toId();
            orderCounts[poolId][order.tick]--;

            emit OrderExecuted(orderId, poolId, order.amount, amountOut);
        } catch {
            // If execution fails, revert the executed flag
            order.executed = false;
        }
    }

    /**
     * @notice Struct for passing data to unlockCallback
     */
    struct UnlockData {
        uint256 orderId;
        PoolKey key;
        bool zeroForOne;
        uint256 amountIn;
    }

    /**
     * @notice Callback for executing the swap
     */
    function unlockCallback(
        bytes calldata data
    ) external override onlyPoolManager returns (bytes memory) {
        UnlockData memory unlockData = abi.decode(data, (UnlockData));

        // Execute the swap
        BalanceDelta delta = poolManager.swap(
            unlockData.key,
            IPoolManager.SwapParams({
                zeroForOne: unlockData.zeroForOne,
                amountSpecified: -int256(unlockData.amountIn), // Exact input
                sqrtPriceLimitX96: unlockData.zeroForOne
                    ? MIN_PRICE_LIMIT
                    : MAX_PRICE_LIMIT
            }),
            ""
        );

        // Settle the input (take from hook to pool)
        Currency inputCurrency = unlockData.zeroForOne
            ? unlockData.key.currency0
            : unlockData.key.currency1;
        poolManager.settle(inputCurrency);

        // Take the output (from pool to hook)
        Currency outputCurrency = unlockData.zeroForOne
            ? unlockData.key.currency1
            : unlockData.key.currency0;
        uint256 amountOut = unlockData.zeroForOne
            ? uint256(int256(delta.amount1()))
            : uint256(int256(delta.amount0()));
        poolManager.take(outputCurrency, address(this), amountOut);

        return abi.encode(amountOut);
    }

    // ========== VIEW FUNCTIONS ==========

    /**
     * @notice Get order details
     */
    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    /**
     * @notice Get claimable amount for an order
     */
    function getClaimable(uint256 orderId) external view returns (uint256) {
        return claimableOutputTokens[orderId];
    }
}
