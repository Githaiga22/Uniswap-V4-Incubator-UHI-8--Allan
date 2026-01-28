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
