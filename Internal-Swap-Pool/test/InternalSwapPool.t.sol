// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title InternalSwapPoolTest
 * @author Allan Robinson
 * @notice Test suite for InternalSwapPool hook
 * @dev Created: February 3, 2026 - Week 3 Homework
 */
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {InternalSwapPool} from "../src/InternalSwapPool.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {HookMiner} from "./utils/HookMiner.sol";

/**
 * @title InternalSwapPoolTest
 * @notice Comprehensive test suite for InternalSwapPool custom pricing hook
 * @dev Tests Return Delta hooks (beforeSwapReturnDelta, afterSwapReturnDelta)
 */
contract InternalSwapPoolTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    // The hook we're testing
    InternalSwapPool hook;

    // Test user addresses
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address lp = makeAddr("lp");

    // Events to test
    event FeesDeposited(PoolId indexed poolId, uint256 amount0, uint256 amount1);
    event FeesDistributed(PoolId indexed poolId, uint256 amount0);
    event InternalSwapExecuted(
        PoolId indexed poolId, uint256 tokenIn, uint256 ethOut, address indexed user
    );

    /**
     * @notice Setup function - runs before each test
     * @dev Sets up Uniswap v4 core contracts and deploys InternalSwapPool hook
     */
    function setUp() public {
        // STEP 1: Deploy Uniswap v4 core contracts
        deployFreshManagerAndRouters();

        // STEP 1.5: Deploy and set up currencies
        (currency0, currency1) = deployMintAndApprove2Currencies();

        // STEP 2: Mine a salt for correct hook address
        // InternalSwapPool needs these permissions:
        // - beforeSwap
        // - afterSwap
        // - beforeSwapReturnDelta
        // - afterSwapReturnDelta
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG
                | Hooks.AFTER_SWAP_FLAG
                | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG
                | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
        );

        // Mine salt for hook address
        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(InternalSwapPool).creationCode,
            abi.encode(address(manager), address(0)) // nativeToken can be address(0) for tests
        );

        // STEP 3: Deploy the hook
        hook = new InternalSwapPool{salt: salt}(address(manager), address(0));
        require(address(hook) == hookAddress, "Hook address mismatch");

        console.log("InternalSwapPool deployed at:", address(hook));

        // STEP 4: Initialize a test pool
        (key,) = initPool(
            currency0, // ETH/WETH
            currency1, // TOKEN
            hook, // Our internal swap pool hook
            3000, // 0.3% fee
            SQRT_PRICE_1_1 // Initial price 1:1
        );

        // STEP 5: Add initial liquidity
        // Give LP tokens
        deal(Currency.unwrap(currency0), lp, 100 ether);
        deal(Currency.unwrap(currency1), lp, 100 ether);

        vm.startPrank(lp);
        IERC20(Currency.unwrap(currency0)).approve(address(modifyLiquidityRouter), type(uint256).max);
        IERC20(Currency.unwrap(currency1)).approve(address(modifyLiquidityRouter), type(uint256).max);

        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 10 ether,
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );
        vm.stopPrank();

        // Give test users tokens
        deal(Currency.unwrap(currency0), alice, 10 ether);
        deal(Currency.unwrap(currency1), alice, 10 ether);
        deal(Currency.unwrap(currency0), bob, 10 ether);
        deal(Currency.unwrap(currency1), bob, 10 ether);

        // Approve router
        vm.prank(alice);
        IERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        vm.prank(alice);
        IERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);

        vm.prank(bob);
        IERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        vm.prank(bob);
        IERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);
    }

    /**
     * @notice Test basic swap without internal pool (no TOKEN fees yet)
     */
    function test_BasicSwap_NoInternalPool() public {
        // Alice swaps 1 ETH for TOKEN
        vm.prank(alice);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true, // ETH → TOKEN
                amountSpecified: -1 ether, // Exact input
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        // Check that fees were captured
        InternalSwapPool.ClaimableFees memory fees = hook.poolFees(key);
        console.log("TOKEN fees captured:", fees.amount1);

        // Should have TOKEN fees (1% of output)
        assertGt(fees.amount1, 0, "No TOKEN fees captured");
        assertEq(fees.amount0, 0, "ETH fees should be 0");
    }

    /**
     * @notice Test internal pool fills TOKEN→ETH swap
     */
    function test_InternalPoolFill() public {
        // STEP 1: Create TOKEN fees (buy swap)
        vm.prank(alice);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true, // ETH → TOKEN
                amountSpecified: -1 ether,
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        InternalSwapPool.ClaimableFees memory feesAfterBuy = hook.poolFees(key);
        uint256 tokenFeesBeforeSell = feesAfterBuy.amount1;
        console.log("TOKEN fees before sell:", tokenFeesBeforeSell);

        assertGt(tokenFeesBeforeSell, 0, "Should have TOKEN fees");

        // STEP 2: Bob sells TOKEN for ETH (should fill from internal pool)
        uint256 bobTokenBalanceBefore = currency1.balanceOf(bob);
        uint256 bobEthBalanceBefore = currency0.balanceOf(bob);

        vm.expectEmit(true, false, false, false);
        emit InternalSwapExecuted(key.toId(), 0, 0, bob); // We don't know exact amounts

        vm.prank(bob);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: false, // TOKEN → ETH
                amountSpecified: -0.1 ether, // Sell 0.1 TOKEN
                sqrtPriceLimitX96: MAX_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        // Check balances changed
        assertLt(currency1.balanceOf(bob), bobTokenBalanceBefore, "Bob should have less TOKEN");
        assertGt(currency0.balanceOf(bob), bobEthBalanceBefore, "Bob should have more ETH");

        // Check hook converted TOKEN fees to ETH fees
        InternalSwapPool.ClaimableFees memory feesAfterSell = hook.poolFees(key);
        console.log("TOKEN fees after sell:", feesAfterSell.amount1);
        console.log("ETH fees after sell:", feesAfterSell.amount0);

        // TOKEN fees should be reduced (used for swap)
        assertLt(feesAfterSell.amount1, tokenFeesBeforeSell, "TOKEN fees should decrease");

        // ETH fees should increase (converted)
        assertGt(feesAfterSell.amount0, 0, "Should have ETH fees from conversion");
    }

    /**
     * @notice Test fee capture in both directions
     */
    function test_FeeCapture_BothDirections() public {
        // Test ETH → TOKEN (fee in TOKEN)
        vm.prank(alice);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -1 ether,
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        InternalSwapPool.ClaimableFees memory fees1 = hook.poolFees(key);
        assertGt(fees1.amount1, 0, "Should capture TOKEN fees");

        // Test TOKEN → ETH (fee in ETH)
        vm.prank(bob);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: -1 ether,
                sqrtPriceLimitX96: MAX_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        InternalSwapPool.ClaimableFees memory fees2 = hook.poolFees(key);
        assertGt(fees2.amount0, fees1.amount0, "Should capture ETH fees");
    }

    /**
     * @notice Test exact output swap with internal pool
     */
    function test_ExactOutput_InternalPool() public {
        // Create TOKEN fees first
        vm.prank(alice);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -2 ether, // Buy with 2 ETH
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        InternalSwapPool.ClaimableFees memory feesBefore = hook.poolFees(key);
        console.log("TOKEN fees available:", feesBefore.amount1);

        // Now do exact output swap (specify ETH to receive)
        vm.prank(bob);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: false, // TOKEN → ETH
                amountSpecified: 0.1 ether, // Want exactly 0.1 ETH
                sqrtPriceLimitX96: MAX_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        InternalSwapPool.ClaimableFees memory feesAfter = hook.poolFees(key);

        // TOKEN fees should be used
        assertLt(feesAfter.amount1, feesBefore.amount1, "TOKEN fees should be used");

        // ETH fees should increase
        assertGt(feesAfter.amount0, feesBefore.amount0, "ETH fees should increase");
    }

    /**
     * @notice Test that internal pool doesn't interfere with ETH→TOKEN swaps
     */
    function test_NoInternalPool_ForBuySwaps() public {
        // Create TOKEN fees
        vm.prank(alice);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -1 ether,
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        InternalSwapPool.ClaimableFees memory feesBefore = hook.poolFees(key);

        // Another ETH→TOKEN swap (should NOT use internal pool)
        vm.prank(bob);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true, // ETH → TOKEN
                amountSpecified: -1 ether,
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        InternalSwapPool.ClaimableFees memory feesAfter = hook.poolFees(key);

        // TOKEN fees should only increase (not decrease)
        assertGt(feesAfter.amount1, feesBefore.amount1, "TOKEN fees should only increase for buy swaps");
    }

    /**
     * @notice Test multiple swaps accumulate fees correctly
     */
    function test_MultipleSwaps_AccumulateFees() public {
        uint256 numSwaps = 5;

        for (uint256 i = 0; i < numSwaps; i++) {
            // Alternate between buy and sell
            bool buySwap = (i % 2 == 0);

            if (buySwap) {
                vm.prank(alice);
                swapRouter.swap(
                    key,
                    IPoolManager.SwapParams({
                        zeroForOne: true,
                        amountSpecified: -0.5 ether,
                        sqrtPriceLimitX96: MIN_PRICE_LIMIT
                    }),
                    PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
                    ZERO_BYTES
                );
            } else {
                vm.prank(bob);
                swapRouter.swap(
                    key,
                    IPoolManager.SwapParams({
                        zeroForOne: false,
                        amountSpecified: -0.3 ether,
                        sqrtPriceLimitX96: MAX_PRICE_LIMIT
                    }),
                    PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
                    ZERO_BYTES
                );
            }
        }

        InternalSwapPool.ClaimableFees memory fees = hook.poolFees(key);
        console.log("Total ETH fees:", fees.amount0);
        console.log("Remaining TOKEN fees:", fees.amount1);

        // Should have accumulated ETH fees
        assertGt(fees.amount0, 0, "Should have ETH fees from sell swaps");
    }

    /**
     * @notice Test fee distribution threshold
     */
    function test_FeeDistribution_BelowThreshold() public {
        // Small swap that won't trigger distribution
        vm.prank(alice);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -0.0001 ether, // Very small swap
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        InternalSwapPool.ClaimableFees memory fees = hook.poolFees(key);

        // Fees should be captured but not distributed (below threshold)
        assertGt(fees.amount1, 0, "Should capture fees");
        assertLt(fees.amount1, hook.DONATE_THRESHOLD_MIN(), "Should be below threshold");
    }

    /**
     * @notice Test gas usage for swaps with internal pool
     */
    function test_Gas_InternalPoolSwap() public {
        // Create TOKEN fees
        vm.prank(alice);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -2 ether,
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        // Measure gas for swap with internal pool
        vm.prank(bob);
        uint256 gasBefore = gasleft();
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: -0.5 ether,
                sqrtPriceLimitX96: MAX_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for swap with internal pool:", gasUsed);

        // Gas should be reasonable (less than 500k)
        assertLt(gasUsed, 500000, "Gas usage too high");
    }

    /**
     * @notice Test hook doesn't break with zero amounts
     */
    function test_EdgeCase_VerySmallSwap() public {
        vm.prank(alice);
        swapRouter.swap(
            key,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: -1 wei, // Minimal swap
                sqrtPriceLimitX96: MIN_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            ZERO_BYTES
        );

        // Should not revert
        assertTrue(true, "Small swap should work");
    }

    /**
     * @notice Test depositFees function
     */
    function test_DepositFees() public {
        uint256 amount0 = 1 ether;
        uint256 amount1 = 100 ether;

        vm.expectEmit(true, false, false, true);
        emit FeesDeposited(key.toId(), amount0, amount1);

        hook.depositFees(key, amount0, amount1);

        InternalSwapPool.ClaimableFees memory fees = hook.poolFees(key);
        assertEq(fees.amount0, amount0, "Amount0 mismatch");
        assertEq(fees.amount1, amount1, "Amount1 mismatch");
    }

    /**
     * @notice Test hook permissions are correctly set
     */
    function test_HookPermissions() public view {
        Hooks.Permissions memory permissions = hook.getHookPermissions();

        assertTrue(permissions.beforeSwap, "beforeSwap should be true");
        assertTrue(permissions.afterSwap, "afterSwap should be true");
        assertTrue(permissions.beforeSwapReturnDelta, "beforeSwapReturnDelta should be true");
        assertTrue(permissions.afterSwapReturnDelta, "afterSwapReturnDelta should be true");

        assertFalse(permissions.beforeInitialize, "beforeInitialize should be false");
        assertFalse(permissions.afterInitialize, "afterInitialize should be false");
        assertFalse(permissions.beforeAddLiquidity, "beforeAddLiquidity should be false");
        assertFalse(permissions.afterAddLiquidity, "afterAddLiquidity should be false");
    }
}
