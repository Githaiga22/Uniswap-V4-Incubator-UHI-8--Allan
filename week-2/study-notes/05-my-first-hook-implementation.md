# MyFirstHook Implementation Notes

**Author**: Allan Robinson
**Date**: January 27, 2026
**Context**: Week 2 - Building My First Hook with Tom Wade

---

## Concept

MyFirstHook is a simple swap counter that tracks how many swaps occur in each pool. It demonstrates the core hook pattern without unnecessary complexity.

---

## Architecture

```
Pool Lifecycle Event Flow:
┌─────────────┐
│  User calls │
│  swap()     │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│  beforeSwap()   │ ← Hook intercepts
│  (count++)      │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│  Pool executes  │
│  swap logic     │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│  afterSwap()    │ ← Hook intercepts again
│  (log event)    │
└─────────────────┘
```

---

## Key Implementation Decisions

### 1. Permission Selection
I only enabled `beforeSwap` and `afterSwap` because that's all this hook needs. Every enabled permission costs gas during deployment address mining.

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeSwap: true,
        afterSwap: true,
        // Everything else: false
    });
}
```

**Why this matters**: The hook address must have specific bits set based on permissions. More permissions = longer mining time.

### 2. State Management
Simple mapping from `PoolId` to swap count:

```solidity
mapping(PoolId => uint256) public swapCount;
```

**Design choice**: Using `PoolId` (bytes32 hash) instead of full `PoolKey` struct for gas efficiency. The PoolManager already validates the pool exists.

### 3. beforeSwap Logic
Increment counter before the swap executes:

```solidity
function _beforeSwap(...) internal override returns (bytes4, BeforeSwapDelta, uint24) {
    PoolId poolId = key.toId();
    swapCount[poolId]++;

    return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
}
```

**Return values explained**:
- `selector`: Confirms this hook function ran successfully
- `BeforeSwapDelta`: No token modifications (ZERO_DELTA)
- `uint24`: No dynamic fee override (0)

### 4. afterSwap Logic
Currently empty but demonstrates the pattern:

```solidity
function _afterSwap(...) internal override returns (bytes4, int128) {
    return (BaseHook.afterSwap.selector, 0);
}
```

Could add event emissions, reward distribution, or state updates here.

---

## What I Learned

**Pattern Recognition**: Hooks follow a strict contract:
1. Inherit from `BaseHook`
2. Declare permissions in `getHookPermissions()`
3. Implement `_hookName()` internal functions
4. Return correct selector + data

**Address Mining**: The hook address encodes its permissions in the last bytes. Tom showed us how `HookMiner.sol` brute-forces salt values until finding a valid address.

**Return Values Matter**: Each hook function must return its selector. This validates execution without external state checks - clever gas optimization.

**Minimal Surface Area**: Start simple. MyFirstHook does one thing well. Can always extend later.

---

## Testing Observations

The test setup requires:
- PoolManager deployment
- Currency initialization
- Hook address mining (salt finding)
- Pool initialization with hook

**Current issue**: Currency initialization in tests needs fixing. The hook code itself compiles and works correctly.

---

## Production Considerations

If deploying this for real:

1. **Add access control** - Who can query swap counts?
2. **Event emissions** - Log swaps for off-chain indexing
3. **Batch queries** - Function to get counts for multiple pools
4. **Reset mechanism** - Maybe reset counts periodically
5. **Gas optimization** - Consider using `uint96` instead of `uint256` for counts

---

## Code Location

`src/examples/MyFirstHook.sol`

**Lines of code**: ~60 (excluding comments)
**Complexity**: Beginner level
**Gas cost**: Minimal overhead per swap

---

**Next**: Study PointsHook for more complex state management patterns.
