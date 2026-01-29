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

    assertEq(hook.getPoints(alice, poolId), POINTS_PER_SWAP * 2);
}
```
</details>

---

## Exercise 3: Gas Benchmarking

### Task
Measure and compare gas costs of hook operations.

**Requirements**:
1. Measure gas for swap with hook
2. Compare to swap without hook
3. Ensure overhead is acceptable (<50k gas)

<details>
<summary>Solution</summary>

```solidity
function testGas_SwapWithHook() public {
    uint256 gasBefore = gasleft();

    vm.prank(alice);
    swap(poolKey, 1 ether);

    uint256 gasUsed = gasBefore - gasleft();
    console.log("Gas used (with hook):", gasUsed);

    assertLt(gasUsed, 200000); // Reasonable limit
}

function testGas_SwapWithoutHook() public {
    // Create pool without hook
    PoolKey memory noHookKey = PoolKey({
        currency0: currency0,
        currency1: currency1,
        fee: 3000,
        tickSpacing: 60,
        hooks: IHooks(address(0))
    });

    uint256 gasBefore = gasleft();

    vm.prank(alice);
    swap(noHookKey, 1 ether);

    uint256 gasUsed = gasBefore - gasleft();
    console.log("Gas used (no hook):", gasUsed);
}

function testGas_HookOverhead() public {
    uint256 withHook = measureSwapGas(poolKey);
    uint256 withoutHook = measureSwapGas(noHookPoolKey);

    uint256 overhead = withHook - withoutHook;
    console.log("Hook overhead:", overhead);

    assertLt(overhead, 50000); // Must be < 50k gas
}
```
</details>

---

## Exercise 4: Fuzz Testing

### Task
Create fuzz tests to verify hook behavior with random inputs.

**Requirements**:
1. Fuzz test point accumulation
2. Fuzz test with multiple users
3. Ensure no overflow/underflow

<details>
<summary>Solution</summary>

```solidity
function testFuzz_PointsAccumulate(uint8 swapCount) public {
    vm.assume(swapCount > 0 && swapCount < 100);

    vm.startPrank(alice);
    for (uint256 i = 0; i < swapCount; i++) {
        swap(poolKey, 1 ether);
    }
    vm.stopPrank();

    uint256 expectedPoints = uint256(swapCount) * POINTS_PER_SWAP;
    assertEq(hook.getPoints(alice, poolId), expectedPoints);
}

function testFuzz_MultipleUsers(
    address user1,
    address user2,
    uint8 swaps1,
    uint8 swaps2
) public {
