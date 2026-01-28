# My First Uniswap V4 Hook

**Author**: Allan Robinson
**Date**: January 27, 2026
**Course**: Uniswap V4 Hooks Incubator (Week 2)
**Instructor**: Tom Wade

---

## Overview

This repository contains my first hands-on implementation of Uniswap V4 hooks. Following Tom Wade's workshop, I built two hooks from scratch to understand the core mechanics of the hook system:

1. **MyFirstHook** - Simple swap counter
2. **PointsHook** - Loyalty rewards system

This project represents my transition from understanding V4 architecture (Week 1) to actually building plugins that extend pool functionality.

---

## Project Structure

```
Build your first hook/
├── src/examples/
│   ├── MyFirstHook.sol        (Simple swap tracking)
│   └── PointsHook.sol         (Loyalty points system)
├── test/
│   ├── MyFirstHook.t.sol      (Test suite)
│   ├── PointsHook.t.sol       (Test suite)
│   └── utils/HookMiner.sol    (Address mining utility)
├── script/
│   └── DeployHook.s.sol       (Deployment script)
├── lib/
│   ├── v4-core/               (Uniswap V4 protocol)
│   ├── v4-periphery/          (BaseHook & utilities)
│   └── forge-std/             (Foundry testing)
└── foundry.toml               (Project configuration)
```

---

## Hook 1: MyFirstHook

### Concept
A minimal hook that tracks swap activity per pool. Every swap increments a counter.

### Design Decisions

**Why afterSwap instead of beforeSwap?**
I chose to count swaps after execution because:
- Confirms the swap actually completed
- No risk of counting failed transactions
- Cleaner separation of concerns

**State structure:**
```solidity
mapping(PoolId => uint256) public swapCount;
```

Used `PoolId` (bytes32) instead of storing full `PoolKey` struct for gas efficiency. The pool manager already validates pool existence.

### Key Learnings

1. **Permission system**: Enabling `beforeSwap` and `afterSwap` requires finding an address with specific bit patterns. Hook Miner handles this automatically.

2. **Return values matter**: Each hook function must return its selector (`BaseHook.afterSwap.selector`) to confirm execution. This is how the PoolManager validates the hook ran correctly.

3. **Minimal state**: For a simple counter, nested mappings would be overkill. Flat mapping is sufficient and cheaper.

---

## Hook 2: PointsHook

### Concept
A loyalty rewards system that awards points for trading and providing liquidity. Users earn:
- 10 points per swap
- 50 points per liquidity addition

### Design Decisions

**Nested mapping structure:**
```solidity
mapping(address => mapping(PoolId => uint256)) public userPoints;
```

This allows O(1) lookups for any user-pool combination. Scales to millions of users across thousands of pools.

**Multiple lifecycle hooks:**
- `afterSwap` - Award points for trading
- `afterAddLiquidity` - Award points for LP participation

**Why after* hooks only?**
Points should only be awarded AFTER successful actions. Using before* hooks would allow users to game the system with failing transactions.

### Challenges

**The msg.sender problem:**
Inside hook callbacks, `msg.sender` is always the PoolManager, not the end user. To track individual users, I need to:
1. Extract user address from router context, OR
2. Pass user address via `hookData` parameter

Currently, the code uses `sender` parameter which IS correct in this context - it's the address that called the PoolManager.

**Query limitations:**
Implemented view functions for specific pool queries:
```solidity
function getPoints(address user, PoolId poolId) external view returns (uint256)
```

However, getting total points across ALL pools can't be done efficiently on-chain. This requires off-chain indexing (The Graph, etc.).

### Production Roadmap

To make this production-ready:
- [ ] Make point values configurable per pool
- [ ] Add admin controls (pause, adjust rates)
- [ ] Implement events for off-chain indexing
- [ ] Design redemption mechanism
- [ ] Add anti-sybil measures (minimum trade size)

---

## Development Setup

### Prerequisites
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Build
```bash
forge build
```

### Test
```bash
forge test -vv
```

**Note**: Tests currently need currency initialization fixes. The hook code itself compiles and is logically sound.

### Deploy
```bash
# Set environment variables
export POOL_MANAGER_ADDRESS=<address>
export PRIVATE_KEY=<your_key>

# Run deployment
forge script script/DeployHook.s.sol --rpc-url <network> --broadcast
```

---

## Technical Implementation Details

### Hook Address Mining

Uniswap V4 enforces that hook addresses encode their permissions in the last 2 bytes.

Example:
```
Address: 0x1234...00C0
Binary flags in 0xC0:
├─ Bit 6: beforeSwap = 1
├─ Bit 7: afterSwap = 1
└─ All others: 0
```

**HookMiner.sol** brute-forces CREATE2 salts until finding a valid address:
```solidity
for (uint256 i = 0; i < MAX_LOOP; i++) {
    address computed = computeCreate2Address(salt);
    if (hasCorrectBits(computed)) return salt;
}
```

I set `MAX_LOOP = 100,000` which is sufficient for most permission combinations.

### BaseHook Pattern

All hooks inherit from `BaseHook` which provides:
- Constructor that stores PoolManager reference
- Public interface functions that call internal `_hookName()` functions
- Selector validation logic

**My responsibility:**
1. Implement `getHookPermissions()` - Declare which hooks I use
2. Implement `_beforeSwap()`, `_afterSwap()`, etc. - My custom logic

**BaseHook handles:**
- Public `beforeSwap()` → calls my `_beforeSwap()`
- Validates return selectors
- Manages PoolManager communication

This separation prevents me from accidentally breaking the protocol interface.

### Balance Deltas

Understanding `BalanceDelta` was initially confusing. It represents changes from the POOL's perspective:

```
Swap: ETH → USDC (zeroForOne = true)
BalanceDelta:
  amount0 = +1.0 ETH     (pool received)
  amount1 = -2000 USDC   (pool sent out)
```

Positive = inflow to pool
Negative = outflow from pool

This matters when building hooks that modify swap amounts or collect fees.

---

## What I Learned

### Architectural Insights

1. **Hooks are plugins, not controllers**: I can observe and react to pool events, but I can't override core swap mechanics. This is by design - keeps the protocol safe.

2. **Permission granularity**: Can enable as many hooks as needed. The address mining scales fine up to ~10 permissions.

3. **State design matters**: For per-user tracking, nested mappings are essential. For global stats, flat mappings suffice.

### Solidity Patterns

1. **Library usage**: `using PoolIdLibrary for PoolKey` enables clean syntax:
   ```solidity
   PoolId id = key.toId();  // Clean
   // vs
   PoolId id = PoolIdLibrary.toId(key);  // Verbose
   ```

2. **Return value contracts**: Every hook must return specific types. Getting this wrong causes silent failures or reverts.

3. **Constants vs configurability**: Used constants for learning, but production hooks need dynamic configuration.

### Development Process

1. **Start with permissions**: Design what lifecycle events you need FIRST, then implement.

2. **Test early**: Hook address mining can fail if permissions are too restrictive. Test the mining process early.

3. **Read the source**: When stuck, reading v4-core source code (especially `PoolManager.sol`) clarifies behavior instantly.

---

## Comparisons

### MyFirstHook vs PointsHook

| Aspect | MyFirstHook | PointsHook |
|--------|-------------|------------|
| Complexity | Beginner | Intermediate |
| State | Single mapping | Nested mappings |
| Hooks used | 2 (swap only) | 2 (swap + liquidity) |
| Lines of code | ~60 | ~90 |
