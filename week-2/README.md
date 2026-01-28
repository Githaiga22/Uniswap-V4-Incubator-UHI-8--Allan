# Week 2: Building Your First Hook

**Period**: January 27, 2026
**Focus**: Hands-On Hook Development
**Instructor**: Tom Wade

---

## Overview

Week 2 was the transition from theory to practice. After understanding V4's architecture in Week 1, this week involved building actual hooks from scratch - writing code, deploying contracts, and seeing the plugin system come to life.

```
WEEK 2 PROGRESSION
══════════════════════════════════════════════════

Theory → Practice → Understanding

Day 1: Workshop                Day 2-7: Deep Work
┌──────────────────┐          ┌──────────────────┐
│ Tom Wade teaches │          │ Build hooks      │
│ Hook fundamentals│    →     │ Document code    │
│ Live coding      │          │ Test & debug     │
│ Q&A session      │          │ Iterate & learn  │
└──────────────────┘          └──────────────────┘
         │                             │
         └──────────┬──────────────────┘
                    ▼
         Two Working Hooks
         + Deep Understanding
```

---

## Workshop Highlights

### The Development Environment

Tom walked us through a complete Foundry setup for V4 hook development. The key insight: hooks are just Solidity contracts that inherit from `BaseHook` and follow specific patterns.

```
Foundry Project Structure:
┌────────────────────────────────────┐
│ src/examples/                      │
│  ├─ MyFirstHook.sol     ← Our code│
│  └─ PointsHook.sol      ← Our code│
│                                    │
│ lib/                               │
│  ├─ v4-core/            ← Protocol│
│  ├─ v4-periphery/       ← Helpers │
│  └─ forge-std/          ← Testing │
│                                    │
│ test/                              │
│  ├─ MyFirstHook.t.sol   ← Tests  │
│  └─ utils/HookMiner.sol ← Tool   │
└────────────────────────────────────┘
```

### Core Concepts Taught

**1. The BaseHook Pattern**

Every hook extends `BaseHook` which provides the protocol interface:

```solidity
contract MyFirstHook is BaseHook {
    // Declare permissions
    function getHookPermissions() public pure override
        returns (Hooks.Permissions memory)

    // Implement lifecycle functions
    function _beforeSwap(...) internal override
    function _afterSwap(...) internal override
}
```

**Key insight**: Internal `_hookName()` functions contain our logic. BaseHook wraps them in public interfaces that the PoolManager calls.

**2. Permission System**

Hooks declare which lifecycle events they need:

```
Available Permissions:
├─ beforeInitialize      ├─ beforeSwap
├─ afterInitialize       ├─ afterSwap
├─ beforeAddLiquidity    ├─ beforeDonate
├─ afterAddLiquidity     ├─ afterDonate
├─ beforeRemoveLiquidity └─ (+ delta modifications)
└─ afterRemoveLiquidity
```

**Critical detail**: The hook's deployed address MUST encode these permissions in its bits. More on this below.

**3. Address Mining**

The most unexpected concept. Your hook can't just deploy anywhere - it needs a specific address.

```
Example Hook Address: 0x1234...00C0

Last 2 bytes (0x00C0) in binary:
0000 0000 1100 0000
         ││
         └┴─ Bits 6 & 7 set

Meaning:
Bit 6 = beforeSwap enabled
Bit 7 = afterSwap enabled
```

**Solution**: Use CREATE2 with salt mining. Tom provided `HookMiner.sol` that brute-forces salts until finding a valid address. This can take seconds to minutes depending on permission combination.

**4. Return Values Contract**

Every hook function must return specific values:

```solidity
// afterSwap must return:
return (
    BaseHook.afterSwap.selector,  // Confirms execution
    0                              // Hook delta (usually 0)
);
```

Wrong selector = transaction reverts. This validates the hook ran correctly without extra state checks.

---

## Hook 1: MyFirstHook

### Concept
Simple swap counter. Tracks how many swaps occur in each pool.

### Architecture

```
Swap Flow with MyFirstHook:
┌─────────────────────────────────┐
│ User initiates swap             │
└────────────┬────────────────────┘
             ▼
┌─────────────────────────────────┐
│ PoolManager calls hook          │
│  → _beforeSwap()                │
│     (no-op, return selector)    │
└────────────┬────────────────────┘
             ▼
┌─────────────────────────────────┐
│ Pool executes swap logic        │
└────────────┬────────────────────┘
             ▼
┌─────────────────────────────────┐
│ PoolManager calls hook          │
│  → _afterSwap()                 │
│     swapCount[poolId]++         │
│     return selector             │
└─────────────────────────────────┘
```

### Implementation

```solidity
contract MyFirstHook is BaseHook {
    mapping(PoolId => uint256) public swapCount;

    function _afterSwap(...) internal override
        returns (bytes4, int128)
    {
        swapCount[key.toId()]++;
        return (BaseHook.afterSwap.selector, 0);
    }
}
```

**Design choices**:
- Used `afterSwap` not `beforeSwap` - count only successful swaps
- Single flat mapping - sufficient for pool-level counters
- No events (yet) - could add for off-chain tracking

### Key Learning

The simplicity is the point. This hook demonstrates the core pattern without distractions:
1. Inherit BaseHook
2. Declare permissions
3. Implement internal functions
4. Return correct selectors

Everything else builds on this foundation.

---

## Hook 2: PointsHook

