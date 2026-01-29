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
```solidity
function testSwapAwardsPoints() public {
    vm.prank(alice);
    swap(poolKey, 1 ether);

    uint256 points = hook.getPoints(alice, poolId);
    assertEq(points, POINTS_PER_SWAP);
}
```

**2. Accumulation**:
```solidity
function testMultipleSwapsAccumulate() public {
    vm.startPrank(alice);
    swap(poolKey, 1 ether);
    swap(poolKey, 1 ether);
    swap(poolKey, 1 ether);
    vm.stopPrank();

    uint256 points = hook.getPoints(alice, poolId);
    assertEq(points, POINTS_PER_SWAP * 3);
}
```

**3. Isolation**:
```solidity
function testPointsIsolatedByPool() public {
    vm.prank(alice);
    swap(pool1Key, 1 ether);

    assertEq(hook.getPoints(alice, pool1Id), POINTS_PER_SWAP);
    assertEq(hook.getPoints(alice, pool2Id), 0);
}
```

**4. Gas Benchmarking**:
```solidity
function testGas_SwapWithHook() public {
    uint256 gasBefore = gasleft();
    vm.prank(alice);
    swap(poolKey, 1 ether);
    uint256 gasUsed = gasBefore - gasleft();

    console.log("Gas overhead:", gasUsed);
    assertLt(gasUsed, 50000); // Ensure hook adds <50k gas
}
```

---

## Deployment Process

### Step 1: Mine Hook Address

**Using HookMiner**:
```bash
forge test --match-test testFindSalt -vv
```

**What it does**:
```solidity
function testFindSalt() public {
    uint160 flags = uint160(
        Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG
    );

    (address hookAddress, bytes32 salt) =
        HookMiner.find(address(this), flags, type(PointsHook).creationCode,
                       abi.encode(poolManager));

    console.log("Hook address:", hookAddress);
    console.log("Salt:", uint256(salt));
}
```

**Tom's tip**: Save the salt! You'll need it for actual deployment.

### Step 2: Deploy Script

**script/DeployPointsHook.s.sol**:
```solidity
contract DeployPointsHook is Script {
    function run() external {
        address poolManager = vm.envAddress("POOL_MANAGER");
        bytes32 salt = bytes32(vm.envUint("HOOK_SALT"));

        vm.startBroadcast();

        PointsHook hook = new PointsHook{salt: salt}(
            IPoolManager(poolManager)
        );

        console.log("Hook deployed at:", address(hook));

        vm.stopBroadcast();
    }
}
```

**Environment variables**:
```bash
export POOL_MANAGER=0x... # Mainnet: 0x000000000004444c...
export HOOK_SALT=0x...
export PRIVATE_KEY=0x...
```

### Step 3: Execute Deployment

**Dry run**:
```bash
forge script script/DeployPointsHook.s.sol --rpc-url sepolia
```

**Actual deployment**:
```bash
forge script script/DeployPointsHook.s.sol \
    --rpc-url sepolia \
    --broadcast \
    --verify
```

**Tom's checklist**:
- [ ] Mined correct salt
- [ ] Hook address matches expected
- [ ] PoolManager address correct for network
- [ ] Gas price acceptable
- [ ] Private key secure
- [ ] Verified on Etherscan

---

## Indexing & Routing Integration

### Why Indexing Matters

**The problem**: Your hook tracks points on-chain, but querying thousands of users across pools is gas-prohibitive.

**The solution**: Off-chain indexing (The Graph, custom indexer)

```
Flow:
┌────────────┐    Events    ┌────────────┐    GraphQL    ┌────────────┐
│ PointsHook │ ────────────→ │  Indexer   │ ────────────→ │  Frontend  │
│ (On-chain) │              │ (Off-chain)│              │   (Webapp)  │
└────────────┘              └────────────┘              └────────────┘
     │                           │                           │
     │ State updates             │ Aggregates data           │ Queries
     └───────────────────────────┴───────────────────────────┘
                          Scalable Architecture
```

### Event Design

**Adding events to PointsHook**:
```solidity
event PointsAwarded(address indexed user, PoolId indexed poolId, uint256 points);
event SwapExecuted(address indexed user, PoolId indexed poolId, uint256 amountIn);

function _assignPoints(address user, PoolId poolId, uint256 points) internal {
    userPoints[user][poolId] += points;
    emit PointsAwarded(user, poolId, points);
}
```

**Tom's guidelines**:
- Index all query-relevant fields
- Emit events for every state change
- Include timestamps if needed (or use block.timestamp)
- Keep event data minimal (gas cost)

### Router Integration

**Universal Router compatibility**:

Uniswap's router needs to know your hook exists and what data it needs.

**hookData parameter**:
```solidity
// Frontend calls:
router.swap({
    key: poolKey,
    params: swapParams,
    hookData: abi.encode(referralCode, slippageTolerance)
});

// Your hook receives:
function _afterSwap(..., bytes calldata hookData) internal override {
    (bytes32 referralCode, uint256 slippage) =
        abi.decode(hookData, (bytes32, uint256));
    // Use custom data
}
```

**Tom's insight**: HookData is your channel to pass user-specific info that doesn't fit in standard swap params.

---

## Questions from the Session

### Q1: Why activate ffi = true in foundry.toml?

**Answer**: FFI (Foreign Function Interface) allows tests to execute external commands. We need this for:
- HookMiner (address mining via external process)
- Complex deployment scripts
- Integration with other tools

**Security**: Never enable in production contracts. Only for testing/scripting.

---

### Q2: Why use Solmate ERC-1155 vs OpenZeppelin?

**Answer**: Gas optimization.

**Comparison**:
```
Operation: transferFrom()
OpenZeppelin: ~25,000 gas (safety checks, hooks, flexibility)
Solmate:      ~21,000 gas (minimal, optimized)
Savings:       4,000 gas per transfer

At scale:
1M transfers/day × 4,000 gas × $0.00001/gas = $40/day savings
```

**Trade-off**: Solmate has fewer features. OpenZeppelin is safer for complex use cases.

**Tom's take**: For production hooks, every gas matters. Use Solmate unless you need OpenZeppelin's extra features.

---

### Q3: What is Solady?

**Answer**: Even more gas-optimized library than Solmate.

**Hierarchy**:
```
Gas Efficiency (low to high):
OpenZeppelin < Solmate < Solady

Documentation (high to low):
OpenZeppelin > Solmate > Solady
```

**Tom's recommendation**: Start with Solmate. Move to Solady only if gas profiling shows you need it.

---

### Q4: deal(address(this), ...) gives you ETH?

**Answer**: Yes, but only in tests.

**How it works**:
```solidity
// In test:
vm.deal(address(this), 100 ether);  // Magic! Now has 100 ETH

// What happened:
// Foundry's VM directly sets balance[address(this)] = 100 ether
// No transfer, no minting - just state manipulation
```

**Production**: This doesn't work on mainnet. Only Foundry's testing VM supports this.

---

### Q5: What does gasleft() do?

**Answer**: Returns remaining gas at that point in execution.

**Usage**:
```solidity
uint256 gasBefore = gasleft();  // e.g., 1,000,000
expensiveOperation();
uint256 gasAfter = gasleft();   // e.g., 950,000

uint256 gasUsed = gasBefore - gasAfter;  // 50,000
```

**Tom's pattern**:
```solidity
function benchmarkSwap() public {
    uint256 g = gasleft();
    swap(...);
    console.log("Gas used:", g - gasleft());
}
```

**Why**: Optimize hooks by measuring gas before/after changes.

---

## Production Checklist

Tom emphasized these before mainnet deployment:

### Pre-Deployment
- [ ] All tests passing (forge test)
- [ ] Gas profiling acceptable (forge test --gas-report)
- [ ] Coverage >90% (forge coverage)
- [ ] Mined correct hook address
- [ ] Salt stored securely
- [ ] Deployment script tested on testnet
- [ ] Events emitted for all state changes

### Deployment
- [ ] Deploy to testnet first (Sepolia)
- [ ] Test on testnet for 24-48 hours
- [ ] Monitor for issues
- [ ] Verify contract on Etherscan
- [ ] Document deployment parameters
- [ ] Deploy to mainnet
- [ ] Double-check hook address matches

### Post-Deployment
- [ ] Initialize hook with pools
- [ ] Set up indexer (The Graph)
- [ ] Create frontend interface
- [ ] Monitor gas costs
- [ ] Track user adoption
- [ ] Prepare incident response plan

---

## Key Takeaways

1. **Testing is not optional**: Production hooks must have comprehensive tests. One bug can drain pools.

2. **Gas matters at scale**: 5,000 gas saved per swap × 1,000 swaps/day = meaningful cost reduction.

3. **Events enable scaling**: On-chain state + off-chain indexing = best of both worlds.

4. **Foundry is powerful**: Cheat codes (vm.*) make testing complex scenarios trivial.

5. **Deployment is deterministic**: CREATE2 + salt = predictable addresses. Use it.

6. **Start simple, iterate**: Deploy simple version, gather data, improve based on real usage.

---

## Resources Mentioned

**Testing**:
- Foundry Book: https://book.getfoundry.sh/
- Forge cheat codes reference
- Solmate source code (gas patterns)

**Deployment**:
- Uniswap V4 hook deployment guide
- Etherscan verification docs
- CREATE2 address calculator

**Indexing**:
- The Graph (subgraph development)
- Event indexing patterns
- GraphQL for frontends

---

## Personal Reflection

Testing felt tedious at first, but Tom showed how it catches bugs before they cost real money. The gas profiling especially - seeing concrete numbers for every optimization.

The deployment process is surprisingly simple once you understand CREATE2. The complexity is in testing, not deploying.

Most valuable insight: Events are how you bridge on-chain logic with off-chain UX. Hook stores minimal state, indexer aggregates it, frontend queries efficiently.

Ready to deploy to testnet tomorrow.

---

**Allan Robinson**
Session 4 Complete - January 29, 2026
