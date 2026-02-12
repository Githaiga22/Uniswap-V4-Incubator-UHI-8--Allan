# Week-4 Class Questions and Answers

**Author**: Allan Robinson
**Date**: February 10, 2026
**Topic**: Limit Orders Hook - Questions from Workshop

---

## Questions Asked During Class

### Q1: Are we filling orders that hit the tick line or every order in the range even if it doesn't hit the line?

**Answer**: We fill orders **at the exact tick** that was crossed.

**Detailed Explanation**:
When the price moves and the tick changes, we iterate through each tick in the range between the last known tick and the current tick. We only execute orders that are placed at ticks that were actually crossed.

**Example**:
```
Last Tick: 0
Current Tick: 120
Tick Spacing: 60

Ticks crossed: 0, 60, 120

Orders at tick 60: EXECUTE [x]
Orders at tick 50: DO NOT EXECUTE [ ] (not a valid tick, not crossed)
Orders at tick 80: DO NOT EXECUTE [ ] (not a valid tick, not crossed)
Orders at tick 120: EXECUTE [x]
```

**Code Reference**:
```solidity
for (int24 tick = lastTick; tick < currentTick; tick += key.tickSpacing) {
    uint256 inputAmount = pendingOrders[key.toId()][tick][executeZeroForOne];
    if (inputAmount > 0) {
        executeOrder(key, tick, executeZeroForOne, inputAmount);
        return (true, currentTick);
    }
}
```

The loop increments by `key.tickSpacing`, ensuring we only check valid ticks. We only execute if there's actually a pending order at that exact tick.

---

### Q2: Our orders will track only the LP which has this hook activated and not other LPs right? And the same for executing.

**Follow-up**: I mean same pair LP, just without the Hook.

**Answer**: Orders are **pool-specific** and isolated to pools with this hook.

**Detailed Explanation**:
Each Uniswap v4 pool has a unique `PoolId` that is derived from:
- Currency0
- Currency1
- Fee tier
- Tick spacing
- **Hook address**

This means:
- Pool A: USDC/ETH with LimitOrder hook at 0.3% fee → Unique PoolId A
- Pool B: USDC/ETH without any hook at 0.3% fee → Different PoolId B
- Pool C: USDC/ETH with different hook at 0.3% fee → Different PoolId C

**Orders placed in Pool A**:
- Are stored with PoolId A as the key
- Only execute when swaps happen in Pool A
- Are completely separate from Pool B or Pool C
- Pool B and C don't even know these orders exist

**Code Reference**:
```solidity
mapping(PoolId poolId =>
    mapping(int24 tickToSellAt =>
        mapping(bool zeroForOne => uint256 inputAmount)))
            public pendingOrders;
```

The first key is `PoolId`, which makes all orders pool-specific.

**Why This Matters**:
- Same token pair can have multiple pools
- Each pool with this hook has its own independent order book
- Orders don't affect other pools, even if they trade the same tokens
- Liquidity in other pools doesn't affect your order execution

---

### Q3: Hi Tom, do you have the new updated v4-periphery without the BaseHook? Can I work with the previous version throughout the UHI or should I use the last version when we get to the Hackathon?

**Context**: There was an issue with BaseHook location changing in v4-periphery.

**What Happened**:
The user spent 4 hours debugging because BaseHook moved from:
- Old location: `v4-periphery/src/base/hooks/BaseHook.sol`
- New location: `v4-periphery/src/utils/BaseHook.sol`

**Answer**: Use the version that works for you during UHI, but be aware of the change.

**Detailed Explanation**:

**The Change**:
v4-periphery underwent restructuring where:
- `BaseHook` moved from `src/base/hooks/` to `src/utils/`
- This is a breaking change for import statements
- The functionality remains the same

**For UHI Course**:
- You can use the older version (before the move) throughout UHI
- Make sure your `forge install` uses a consistent version
- Pin to a specific commit if needed:
  ```bash
  forge install Uniswap/v4-periphery@<commit-hash>
  ```

**For Hackathon**:
- Use the latest version to ensure compatibility
- Update your imports:
  ```solidity
  // Old (may not work with latest)
  import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

  // New (current location)
  import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
  ```

**Best Practice**:
1. Check which version your project is using:
   ```bash
   cd lib/v4-periphery
   git log --oneline -1
   ```

2. If you need to switch versions:
   ```bash
   cd lib/v4-periphery
   git checkout <commit-hash-you-want>
   cd ../..
   ```

3. Update imports accordingly

**Why This Matters**:
- Compiler errors if import path is wrong
- Wastes time debugging (as you experienced!)
- Project won't compile until fixed

**Pro Tip**:
Add this to your project's README to help collaborators:
```markdown
## v4-periphery Version
This project uses v4-periphery commit: <hash>
BaseHook location: src/utils/BaseHook.sol
```

---

## Additional Technical Notes

### Debugging Import Issues

If you encounter import errors:

1. **Check file exists**:
   ```bash
   ls lib/v4-periphery/src/utils/BaseHook.sol
   ls lib/v4-periphery/src/base/hooks/BaseHook.sol
   ```

2. **Check remappings**:
   ```bash
   forge remappings
   ```

3. **Try both import paths** to see which works:
   ```solidity
   import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
   // or
   import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
   ```

4. **Clear cache and rebuild**:
   ```bash
   forge clean
   forge build
   ```

### Version Management Best Practices

**For Learning/UHI**:
- Stick with one version that works
- Don't update mid-project unless necessary
- Document which version you're using

**For Production/Hackathon**:
- Use latest stable version
- Test thoroughly after any updates
- Be aware of breaking changes

---

## Summary

| Question | Answer | Key Takeaway |
|----------|--------|--------------|
| Orders at exact tick or range? | Exact tick only | Orders only execute when tick crosses their specific tick value |
| Orders pool-specific? | Yes, completely isolated | Each pool has its own order book, tracked by unique PoolId |
| BaseHook version issue? | Can use old version, but update for hackathon | Import path changed, be aware and document your version |

---

## References

- [v4-core PoolId Documentation](https://docs.uniswap.org/contracts/v4/concepts/pools)
- [v4-periphery GitHub](https://github.com/Uniswap/v4-periphery)
- [Foundry Book - Dependencies](https://book.getfoundry.sh/projects/dependencies)
