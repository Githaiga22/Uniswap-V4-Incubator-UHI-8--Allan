# Session 4: Testing and Deploying Your First Hook

**Author**: Allan Robinson
**Date**: January 29, 2026
**Context**: Week 2 - Final Session (Testing & Deployment)
**Instructor**: Tom Wade

---

## Overview

Session 4 marked the completion of Week 2, transitioning from building hooks to testing and deploying them. Tom walked us through expanding PointsHook with comprehensive test suites, understanding Foundry's testing framework, and preparing for mainnet deployment.

```
Development Lifecycle:
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Build Hook  │ →  │  Test Hook   │ →  │ Deploy Hook  │
│  (Session 3) │    │ (Session 4)  │    │ (Session 4)  │
└──────────────┘    └──────────────┘    └──────────────┘
                            ↓
                    ┌──────────────┐
                    │ Index & Route│
                    │  (Production)│
                    └──────────────┘
```

---

## Core Topics Covered

### 1. Testing Philosophy

**Local vs Forked Testing**:
```
Local Testing:
├─ Runs entirely on your machine
├─ Fast execution
├─ No external dependencies
└─ Perfect for unit tests

Forked Testing:
├─ Takes mainnet state at specific block
├─ Runs locally with real data
├─ Slower but realistic
└─ Perfect for integration tests
```

**Tom's approach**: Start with local tests for logic, use forked tests for integration with real pools.

### 2. Foundry Configuration Deep Dive

**foundry.toml breakdown**:
```toml
[profile.default]
ffi = true                    # Allows external process execution
optimizer = true              # Enable Solidity optimizer
optimizer_runs = 1000000      # Optimize for deployment, not compilation
via_ir = true                 # Use intermediate representation (better optimization)
fs_permissions = [...]        # File system access for scripts
```

**Why ffi = true?**

Tom explained: FFI (Foreign Function Interface) allows Foundry to execute external commands during tests. Critical for:
- Running address mining scripts (HookMiner)
- Executing deployment scripts
- Integration with external tools

**Security note**: Only enable in dev, NEVER in production contracts.

### 3. Gas Optimization Patterns

**Solmate vs OpenZeppelin**:

Tom showed gas comparisons demonstrating why we use Solmate:

```
ERC-1155 Transfer Gas Cost:
OpenZeppelin: ~25,000 gas
Solmate:      ~21,000 gas
Savings:       4,000 gas (16% reduction)

Why?
├─ Solmate: Minimal abstractions
├─ OpenZeppelin: Safety checks + flexibility
└─ Trade-off: Less features = more gas efficient
```

**When to use each**:
- Solmate: Production contracts where gas matters
- OpenZeppelin: Prototypes, learning, safety-critical code

**Solady mention**: Tom briefly mentioned Solady as even more gas-optimized but with less documentation. For learning, Solmate is better.

---

## Testing Framework Essentials

### Forge Test Verbosity Levels

Tom demonstrated the progression of verbosity:

```bash
forge test              # Silent (only pass/fail)
forge test -v           # Show test names
forge test -vv          # Show logs
forge test -vvv         # Show stack traces
forge test -vvvv        # Show setup traces
forge test -vvvvv       # Show all internal calls
```

**My usage pattern**:
- Development: `-vv` (see my console.log statements)
- Debugging: `-vvvv` (see exactly where it fails)
- Gas profiling: `--gas-report`

### Essential Cheat Codes

**vm.deal()** - Give address ETH:
```solidity
vm.deal(address(this), 100 ether);  // Give contract 100 ETH
vm.deal(alice, 10 ether);           // Give alice 10 ETH
```

**Why this works**: Foundry's VM can manipulate state freely in tests. This sets the balance directly without needing transfers.

**vm.rollFork()** - Time travel in forked tests:
```solidity
vm.rollFork(blockNumber);           // Jump to specific block
vm.rollFork(block.number + 100);    // Fast forward 100 blocks
```

**Use case**: Test how hook behaves over time, simulate market conditions.

**gasleft()** - Measure gas consumption:
```solidity
uint256 gasBefore = gasleft();
// Function call
uint256 gasUsed = gasBefore - gasleft();
console.log("Gas used:", gasUsed);
```

**Tom's insight**: Use this to compare implementations and ensure optimizations actually reduce gas.

### Coverage Analysis

**Command**:
```bash
forge coverage --report summary
```

**Output**:
```
| File               | % Lines | % Statements | % Branches | % Funcs |
|--------------------|---------|--------------|------------|---------|
| PointsHook.sol     | 100.00% | 100.00%      | 75.00%     | 100.00% |
```

**Tom's guideline**: Aim for >90% coverage on core logic. 100% isn't always necessary (some edge cases are impractical to test).

---

## Code Pattern: _assignPoints

Tom introduced a cleaner pattern for point assignment:

**Before** (repetitive):
```solidity
function _afterSwap(...) internal override {
    PoolId poolId = key.toId();
    userPoints[sender][poolId] += POINTS_PER_SWAP;
    totalSwaps[poolId]++;
    return (BaseHook.afterSwap.selector, 0);
}

function _afterAddLiquidity(...) internal override {
    PoolId poolId = key.toId();
    userPoints[sender][poolId] += POINTS_PER_LIQUIDITY;
    totalLiquidityOps[poolId]++;
    return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
}
```

**After** (DRY principle):
```solidity
function _assignPoints(address user, PoolId poolId, uint256 points) internal {
    userPoints[user][poolId] += points;
    emit PointsAwarded(user, poolId, points);
}

function _afterSwap(...) internal override {
    _assignPoints(sender, key.toId(), POINTS_PER_SWAP);
    totalSwaps[key.toId()]++;
    return (BaseHook.afterSwap.selector, 0);
}

function _afterAddLiquidity(...) internal override {
    _assignPoints(sender, key.toId(), POINTS_PER_LIQUIDITY);
    totalLiquidityOps[key.toId()]++;
    return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
}
```

**Benefits**:
- Centralized logic (easier to modify)
- Consistent event emissions
- Better testability (can test _assignPoints in isolation)
- Gas efficiency (function inlining)

---

## Testing Strategy

### Test Structure

Tom showed us the standard pattern:

```solidity
contract PointsHookTest is Test {
    // 1. State variables
    PointsHook hook;
    PoolManager poolManager;
    address alice = makeAddr("alice");

    // 2. Setup
    function setUp() public {
        // Deploy dependencies
        // Initialize hook
        // Create test pools
    }

    // 3. Unit tests (test one thing)
    function testSwapAwardsPoints() public { ... }

    // 4. Integration tests (test workflows)
    function testMultipleSwapsAccumulatePoints() public { ... }

    // 5. Edge cases
    function testZeroPointsWhenNoActivity() public { ... }

    // 6. Fuzz tests (random inputs)
    function testFuzz_PointsAlwaysPositive(uint256 swaps) public { ... }
}
```

### Key Test Cases for PointsHook

**1. Basic Functionality**:
