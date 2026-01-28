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

### Concept
Loyalty rewards system. Award points for trading and providing liquidity.

### Architecture

```
Points Economy:
┌────────────────────────────────────┐
│         User Actions               │
├────────────────────────────────────┤
│                                    │
│ Swap           → 10 points         │
│ Add Liquidity  → 50 points         │
│ Remove Liquidity → 0 points        │
│ Donate         → 0 points          │
│                                    │
└────────────────────────────────────┘

State Structure:
User → Pool → Points Balance
 │      │
 ▼      ▼
0x123  poolA  →  100 pts
0x123  poolB  →  250 pts
0x456  poolA  →   50 pts
```

### Implementation

```solidity
contract PointsHook is BaseHook {
    mapping(address => mapping(PoolId => uint256)) public userPoints;

    uint256 public constant POINTS_PER_SWAP = 10;
    uint256 public constant POINTS_PER_LIQUIDITY = 50;

    function _afterSwap(address sender, ...) internal override {
        userPoints[sender][key.toId()] += POINTS_PER_SWAP;
        return (BaseHook.afterSwap.selector, 0);
    }

    function _afterAddLiquidity(address sender, ...) internal override {
        userPoints[sender][key.toId()] += POINTS_PER_LIQUIDITY;
        return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }
}
```

**Design choices**:
- Nested mappings - enables per-user per-pool tracking
- Constants for point values - should be configurable in production
- Multiple hooks (swap + liquidity) - shows how to combine events
- View functions - makes data queryable by frontends

### Challenges Faced

**The sender context issue**:
Initially confused about who `sender` represents in hook callbacks. Turns out it's the address that called the PoolManager, which IS the end user in this context. No additional extraction needed.

**Total points calculation**:
Can't efficiently calculate user's total points across ALL pools on-chain. Would require iterating through all pools or maintaining a separate aggregate. Solution: use events + off-chain indexing.

---

## Technical Deep Dives

### Hook Deployment Process

1. **Write hook code** with desired permissions
2. **Run HookMiner** to find valid CREATE2 salt
3. **Deploy with CREATE2** using that salt
4. **Address automatically** has correct permission bits
5. **Initialize pools** that use this hook

```bash
# Example mining command
forge test --match-test testFindSalt -vv

# Output: Found salt 0x1234 → Address 0x...00C0
```

### Type System Mastery

**PoolKey vs PoolId**:
```solidity
struct PoolKey {
    Currency currency0;
    Currency currency1;
    uint24 fee;
    int24 tickSpacing;
    IHooks hooks;
}

PoolId = keccak256(abi.encode(PoolKey))
```

PoolKey is full pool specification. PoolId is hash for storage keys. Always use `key.toId()` for mapping keys.
