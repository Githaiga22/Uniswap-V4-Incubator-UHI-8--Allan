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
