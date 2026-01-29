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
    vm.assume(user1 != address(0) && user2 != address(0));
    vm.assume(user1 != user2);
    vm.assume(swaps1 < 50 && swaps2 < 50);

    vm.startPrank(user1);
    for (uint256 i = 0; i < swaps1; i++) {
        swap(poolKey, 1 ether);
    }
    vm.stopPrank();

    vm.startPrank(user2);
    for (uint256 i = 0; i < swaps2; i++) {
        swap(poolKey, 1 ether);
    }
    vm.stopPrank();

    assertEq(hook.getPoints(user1, poolId), swaps1 * POINTS_PER_SWAP);
    assertEq(hook.getPoints(user2, poolId), swaps2 * POINTS_PER_SWAP);
}

function testFuzz_NoOverflow(uint256 largeAmount) public {
    vm.assume(largeAmount < type(uint256).max / POINTS_PER_SWAP);

    for (uint256 i = 0; i < largeAmount; i++) {
        vm.prank(alice);
        swap(poolKey, 1 ether);
    }

    uint256 points = hook.getPoints(alice, poolId);
    assertGe(points, 0);
}
```
</details>

---

## Exercise 5: Fork Testing

### Task
Test hook integration with mainnet pools (forked).

**Requirements**:
1. Fork mainnet at specific block
2. Test hook with real pool
3. Verify behavior matches expectations

<details>
<summary>Solution</summary>

```bash
# Run test with fork
forge test --match-test testFork --fork-url $MAINNET_RPC --fork-block-number 19000000 -vv
```

```solidity
function testFork_IntegrationWithMainnet() public {
    // Fork mainnet
    vm.createSelectFork(vm.envString("MAINNET_RPC"), 19000000);

    // Get mainnet PoolManager
    IPoolManager poolManager = IPoolManager(
        0x000000000004444c5dc75cb358380d2e3de08a90
    );

    // Deploy hook on fork
    PointsHook forkHook = new PointsHook(poolManager);

    // Test with real mainnet state
    // (Actual implementation depends on mainnet pools)
}

function testFork_RollForward() public {
    vm.createSelectFork(vm.envString("MAINNET_RPC"));

    uint256 currentBlock = block.number;

    // Perform action
    vm.prank(alice);
    swap(poolKey, 1 ether);

    // Fast forward 100 blocks
    vm.rollFork(currentBlock + 100);

    // Verify state persists
    uint256 points = hook.getPoints(alice, poolId);
    assertEq(points, POINTS_PER_SWAP);
}
```
</details>

---

## Exercise 6: Coverage Analysis

### Task
Achieve >90% test coverage for PointsHook.

**Steps**:
1. Run `forge coverage --report summary`
2. Identify uncovered lines
3. Write tests for missing coverage
4. Re-run and verify >90%

<details>
<summary>Solution</summary>

```bash
# Check current coverage
forge coverage --report summary

# Output:
# | File           | % Lines | % Statements | % Branches | % Funcs |
# |----------------|---------|--------------|------------|---------|
# | PointsHook.sol | 85.00%  | 85.00%       | 75.00%     | 100.00% |

# Identify missing tests:
forge coverage --report debug | grep "PointsHook"

# Add tests for uncovered paths:
# - Edge cases (zero amounts, max values)
# - Error conditions (reverts)
# - All code branches

# Example: Test view functions
function testGetPointsForNewUser() public {
    assertEq(hook.getPoints(bob, poolId), 0);
}

function testGetSwapCountForNewPool() public {
    PoolId newPoolId = PoolId.wrap(bytes32(uint256(999)));
    assertEq(hook.getSwapCount(newPoolId), 0);
}

# Re-run coverage
forge coverage --report summary

# Target: >90% all categories
```
</details>

---

## Exercise 7: Deployment Testing

### Task
Test deployment process on local testnet (Anvil).

**Requirements**:
1. Start Anvil node
2. Deploy PoolManager
3. Mine hook address
4. Deploy hook
5. Verify deployment

<details>
<summary>Solution</summary>

```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy
forge script script/DeployPointsHook.s.sol \
    --rpc-url http://localhost:8545 \
    --broadcast \
    -vvvv
```

```solidity
// script/DeployPointsHook.s.sol
contract DeployPointsHook is Script {
    function run() external {
        address poolManager = vm.envAddress("POOL_MANAGER");

        uint160 flags = uint160(
            Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            vm.addr(vm.envUint("PRIVATE_KEY")),
            flags,
            type(PointsHook).creationCode,
            abi.encode(poolManager)
        );

        console.log("Expected hook address:", hookAddress);
        console.log("Salt:", uint256(salt));

        vm.startBroadcast();

        PointsHook hook = new PointsHook{salt: salt}(
            IPoolManager(poolManager)
        );

        require(address(hook) == hookAddress, "Address mismatch");

        console.log("Hook deployed at:", address(hook));

        vm.stopBroadcast();
    }
