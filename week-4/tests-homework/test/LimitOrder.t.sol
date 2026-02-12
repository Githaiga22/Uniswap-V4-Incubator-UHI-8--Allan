// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";

import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {EasyPosm} from "v4-periphery/test/utils/EasyPosm.sol";
import {Fixtures} from "v4-periphery/test/utils/Fixtures.sol";

import {LimitOrder} from "../src/LimitOrder.sol";

contract LimitOrderTest is Test, Fixtures {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    LimitOrder hook;
    PoolId poolId;

    uint256 tokenId;
    int24 tickLower;
    int24 tickUpper;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        // Deploy v4-core and router contracts
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        // Deploy hook to an address with the correct flags
        address flags = address(
            uint160(
                Hooks.AFTER_INITIALIZE_FLAG |
                Hooks.AFTER_SWAP_FLAG
            ) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
        );
        bytes memory constructorArgs = abi.encode(manager);
        deployCodeTo("LimitOrder.sol:LimitOrder", constructorArgs, flags);
        hook = LimitOrder(flags);

        // Create the pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(hook));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);

        // Provide full-range liquidity to the pool
        tickLower = TickMath.minUsableTick(key.tickSpacing);
        tickUpper = TickMath.maxUsableTick(key.tickSpacing);

        uint128 liquidityAmount = 100e18;

        (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts
            .getAmountsForLiquidity(
                SQRT_PRICE_1_1,
                TickMath.getSqrtPriceAtTick(tickLower),
                TickMath.getSqrtPriceAtTick(tickUpper),
                liquidityAmount
            );

        (tokenId, ) = posm.mint(
            key,
            tickLower,
            tickUpper,
            liquidityAmount,
            amount0Expected + 1,
            amount1Expected + 1,
            address(this),
            block.timestamp,
            ZERO_BYTES
        );

        // Fund test users
        deal(Currency.unwrap(currency0), alice, 1000 ether);
        deal(Currency.unwrap(currency1), alice, 1000 ether);
        deal(Currency.unwrap(currency0), bob, 1000 ether);
        deal(Currency.unwrap(currency1), bob, 1000 ether);

        // Approve hook to spend tokens
        vm.startPrank(alice);
        currency0.approve(address(hook), type(uint256).max);
        currency1.approve(address(hook), type(uint256).max);
        currency0.approve(address(swapRouter), type(uint256).max);
        currency1.approve(address(swapRouter), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        currency0.approve(address(hook), type(uint256).max);
        currency1.approve(address(hook), type(uint256).max);
        currency0.approve(address(swapRouter), type(uint256).max);
        currency1.approve(address(swapRouter), type(uint256).max);
        vm.stopPrank();
    }

    function test_PlaceOrder() public {
        vm.startPrank(alice);

        uint256 amount = 1 ether;
        int24 targetTick = 100;

        uint256 orderId = hook.placeOrder(key, targetTick, amount, true);

        // Verify order was created
        LimitOrder.Order memory order = hook.getOrder(orderId);
        assertEq(order.owner, alice);
        assertEq(order.tick, targetTick);
        assertEq(order.amount, amount);
        assertTrue(order.zeroForOne);
        assertFalse(order.executed);

        // Verify claim tokens were minted
        assertEq(hook.balanceOf(alice, orderId), amount);

        // Verify order count updated
        assertEq(hook.orderCounts(poolId, targetTick), 1);

        vm.stopPrank();
    }

    function test_CancelOrder() public {
        vm.startPrank(alice);

        uint256 amount = 1 ether;
        int24 targetTick = 100;

        // Place order
        uint256 orderId = hook.placeOrder(key, targetTick, amount, true);

        uint256 balanceBefore = currency0.balanceOfSelf();

        // Cancel order
        hook.cancelOrder(orderId, key);

        // Verify tokens were returned
        uint256 balanceAfter = currency0.balanceOfSelf();
        assertEq(balanceAfter - balanceBefore, amount);

        // Verify claim tokens were burned
        assertEq(hook.balanceOf(alice, orderId), 0);

        // Verify order marked as executed
        LimitOrder.Order memory order = hook.getOrder(orderId);
        assertTrue(order.executed);

        // Verify order count decremented
        assertEq(hook.orderCounts(poolId, targetTick), 0);

        vm.stopPrank();
    }

    function test_CancelOrder_RevertIfNotOwner() public {
        vm.prank(alice);
        uint256 orderId = hook.placeOrder(key, 100, 1 ether, true);

        vm.prank(bob);
        vm.expectRevert(LimitOrder.NotOrderOwner.selector);
        hook.cancelOrder(orderId, key);
    }

    function test_ExecuteOrder_OnTickCrossing() public {
        vm.startPrank(alice);

        uint256 amount = 0.01 ether;
        int24 targetTick = 60; // One tick spacing away

        // Place a sell order (zeroForOne = true)
        uint256 orderId = hook.placeOrder(key, targetTick, amount, true);

        vm.stopPrank();

        // Now bob swaps to move the price up and cross the tick
        vm.startPrank(bob);

        bool zeroForOne = false; // Buying token0 with token1 (price goes up)
        int256 amountSpecified = 1 ether;
        BalanceDelta swapDelta = swap(
            key,
            zeroForOne,
            amountSpecified,
            ZERO_BYTES
        );

        vm.stopPrank();

        // Verify order was executed
        LimitOrder.Order memory order = hook.getOrder(orderId);
        assertTrue(order.executed);

        // Verify claimable tokens were stored
        uint256 claimable = hook.getClaimable(orderId);
        assertGt(claimable, 0);
    }

    function test_RedeemTokens() public {
        vm.startPrank(alice);

        uint256 amount = 0.01 ether;
        int24 targetTick = 60;

        // Place order
        uint256 orderId = hook.placeOrder(key, targetTick, amount, true);

        vm.stopPrank();

        // Execute order by swapping
        vm.prank(bob);
        swap(key, false, 1 ether, ZERO_BYTES);

        // Redeem output tokens
        vm.startPrank(alice);

        uint256 claimable = hook.getClaimable(orderId);
        assertGt(claimable, 0);

        uint256 balanceBefore = currency1.balanceOfSelf();

        // Redeem claim tokens
        hook.redeem(orderId, amount, key);

        uint256 balanceAfter = currency1.balanceOfSelf();
        uint256 received = balanceAfter - balanceBefore;

        // Verify tokens were received
        assertEq(received, claimable);

        // Verify claim tokens were burned
        assertEq(hook.balanceOf(alice, orderId), 0);

        vm.stopPrank();
    }

    function test_Redeem_RevertIfNotExecuted() public {
        vm.startPrank(alice);

        uint256 orderId = hook.placeOrder(key, 100, 1 ether, true);

        // Try to redeem before execution
        vm.expectRevert(LimitOrder.OrderNotExecuted.selector);
        hook.redeem(orderId, 1 ether, key);

        vm.stopPrank();
    }

    function test_MultipleOrders_SameTick() public {
        int24 targetTick = 60;

        // Alice places first order
        vm.prank(alice);
        uint256 orderId1 = hook.placeOrder(key, targetTick, 0.01 ether, true);

        // Bob places second order at same tick
        vm.prank(bob);
        uint256 orderId2 = hook.placeOrder(key, targetTick, 0.02 ether, true);

        // Verify order count
        assertEq(hook.orderCounts(poolId, targetTick), 2);

        // Execute orders by swapping
        vm.prank(alice);
        swap(key, false, 2 ether, ZERO_BYTES);

        // Verify both orders executed
        assertTrue(hook.getOrder(orderId1).executed);
        assertTrue(hook.getOrder(orderId2).executed);

        // Verify both have claimable tokens
        assertGt(hook.getClaimable(orderId1), 0);
        assertGt(hook.getClaimable(orderId2), 0);
    }

    function test_OrderNotExecuted_IfTickNotCrossed() public {
        vm.startPrank(alice);

        int24 targetTick = 300; // Far away tick

        uint256 orderId = hook.placeOrder(key, targetTick, 0.01 ether, true);

        vm.stopPrank();

        // Small swap that doesn't cross the target tick
        vm.prank(bob);
        swap(key, true, -0.001 ether, ZERO_BYTES);

        // Verify order not executed
        LimitOrder.Order memory order = hook.getOrder(orderId);
        assertFalse(order.executed);
        assertEq(hook.getClaimable(orderId), 0);
    }

    function test_PartialRedeem() public {
        vm.startPrank(alice);

        uint256 amount = 1 ether;
        int24 targetTick = 60;

        uint256 orderId = hook.placeOrder(key, targetTick, amount, true);

        vm.stopPrank();

        // Execute order
        vm.prank(bob);
        swap(key, false, 2 ether, ZERO_BYTES);

        // Redeem only half
        vm.startPrank(alice);

        uint256 totalClaimable = hook.getClaimable(orderId);
        uint256 halfAmount = amount / 2;

        uint256 balanceBefore = currency1.balanceOfSelf();
        hook.redeem(orderId, halfAmount, key);
        uint256 balanceAfter = currency1.balanceOfSelf();

        uint256 received = balanceAfter - balanceBefore;
        uint256 expectedHalf = totalClaimable / 2;

        // Verify received proportional amount
        assertEq(received, expectedHalf);

        // Verify half of claim tokens remain
        assertEq(hook.balanceOf(alice, orderId), halfAmount);

        // Redeem the rest
        hook.redeem(orderId, halfAmount, key);

        // Verify all claim tokens burned
        assertEq(hook.balanceOf(alice, orderId), 0);

        vm.stopPrank();
    }

    function test_MultipleTickCrossings() public {
        // Place orders at multiple ticks
        vm.startPrank(alice);
        uint256 order1 = hook.placeOrder(key, 60, 0.01 ether, true);
        uint256 order2 = hook.placeOrder(key, 120, 0.01 ether, true);
        uint256 order3 = hook.placeOrder(key, 180, 0.01 ether, true);
        vm.stopPrank();

        // Large swap crosses all three ticks
        vm.prank(bob);
        swap(key, false, 5 ether, ZERO_BYTES);

        // Verify all orders executed
        assertTrue(hook.getOrder(order1).executed);
        assertTrue(hook.getOrder(order2).executed);
        assertTrue(hook.getOrder(order3).executed);
    }

    function test_BidirectionalOrders() public {
        int24 currentTick = 0;

        // Alice places sell order (zeroForOne = true) above current price
        vm.prank(alice);
        uint256 sellOrder = hook.placeOrder(key, 60, 0.01 ether, true);

        // Bob places buy order (zeroForOne = false) below current price
        vm.prank(bob);
        uint256 buyOrder = hook.placeOrder(key, -60, 0.01 ether, false);

        // Price moves up, triggering sell order
        vm.prank(alice);
        swap(key, false, 1 ether, ZERO_BYTES);

        assertTrue(hook.getOrder(sellOrder).executed);
        assertFalse(hook.getOrder(buyOrder).executed);

        // Price moves down, triggering buy order
        vm.prank(alice);
        swap(key, true, -2 ether, ZERO_BYTES);

        assertTrue(hook.getOrder(buyOrder).executed);
    }

    // ========== HELPER FUNCTIONS ==========

    function swap(
        PoolKey memory _key,
        bool _zeroForOne,
        int256 _amountSpecified,
        bytes memory _hookData
    ) internal returns (BalanceDelta delta) {
        delta = swapRouter.swap(
            _key,
            IPoolManager.SwapParams({
                zeroForOne: _zeroForOne,
                amountSpecified: _amountSpecified,
                sqrtPriceLimitX96: _zeroForOne
                    ? MIN_PRICE_LIMIT
                    : MAX_PRICE_LIMIT
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            _hookData
        );
    }

    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;
}
