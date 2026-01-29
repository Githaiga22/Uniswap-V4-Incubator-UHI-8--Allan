# Week 2: Testing Exercises

**Author**: Allan Robinson
**Date**: January 29, 2026
**Focus**: Hands-on testing practice

---

## Exercise 1: Write Basic Test Cases

### Task
Create test cases for MyFirstHook swap counter functionality.

**Requirements**:
1. Test that swaps increment counter
2. Test that counter is isolated per pool
3. Test that multiple swaps accumulate correctly

<details>
<summary>Solution</summary>

```solidity
// test/MyFirstHook.t.sol
contract MyFirstHookTest is Test {
    MyFirstHook hook;
    PoolKey poolKey;
    PoolId poolId;

    function setUp() public {
        // Deploy hook and initialize pool
        // (Setup code from workshop)
    }

    function testSwapIncrementsCounter() public {
        uint256 countBefore = hook.swapCount(poolId);

        vm.prank(alice);
        swap(poolKey, 1 ether);

        uint256 countAfter = hook.swapCount(poolId);
        assertEq(countAfter, countBefore + 1);
    }

    function testCounterIsolatedByPool() public {
        vm.prank(alice);
        swap(pool1Key, 1 ether);

        assertEq(hook.swapCount(pool1Id), 1);
        assertEq(hook.swapCount(pool2Id), 0);
    }

    function testMultipleSwapsAccumulate() public {
        vm.startPrank(alice);
        swap(poolKey, 1 ether);
        swap(poolKey, 1 ether);
        swap(poolKey, 1 ether);
        vm.stopPrank();

        assertEq(hook.swapCount(poolId), 3);
    }
}
```
</details>

---

## Exercise 2: Test Event Emissions

### Task
Verify that PointsHook emits correct events.

**Requirements**:
1. Test PointsAwarded event on swap
2. Test event parameters are correct
3. Test multiple events in sequence

<details>
<summary>Solution</summary>

```solidity
function testSwapEmitsPointsAwardedEvent() public {
    vm.expectEmit(true, true, false, true);
    emit PointsAwarded(alice, poolId, POINTS_PER_SWAP);

    vm.prank(alice);
    swap(poolKey, 1 ether);
}

function testMultipleEventsEmitted() public {
    vm.startPrank(alice);

    vm.expectEmit(true, true, false, true);
    emit PointsAwarded(alice, poolId, POINTS_PER_SWAP);
    swap(poolKey, 1 ether);

    vm.expectEmit(true, true, false, true);
    emit PointsAwarded(alice, poolId, POINTS_PER_SWAP);
    swap(poolKey, 1 ether);

    vm.stopPrank();
