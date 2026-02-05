# AfterSwap Hook Implementation Challenges

**Author**: Allan Robinson
**Date**: February 5, 2026
**Project**: InternalSwapPool - Uniswap V4 Custom Pricing Curve Hook

---

## Overview

The `afterSwap` hook function proved to be one of the most challenging aspects of implementing the InternalSwapPool hook. This document details the issues encountered, the debugging process, and the solutions implemented to make the tests pass.

## Initial Test Status

- **Starting Point**: 3/11 tests passing
- **After Fixes**: 5/11 tests passing
- **Tests Fixed**: `test_BasicSwap_NoInternalPool`, `test_FeeDistribution_BelowThreshold`

## Challenge 1: Arithmetic Underflow During Token Transfers

### The Problem

```
Error: panic: arithmetic underflow or overflow (0x11)
PoolManager trying to transfer 30253085054698887 tokens
But only has 29953549559107810 tokens available
Difference: 299535495591077 (the fee amount!)
```

**8/11 tests failing** with this error.

### Root Cause

The hook was performing **double-accounting** of fees:

```solidity
// WRONG APPROACH (Original Code)
function afterSwap(...) {
    // 1. Physically take tokens from PoolManager
    swapFeeCurrency.take(poolManager, address(this), swapFee, false);

    // 2. ALSO return negative delta to reduce user output
    hookDeltaUnspecified_ = -int128(int256(swapFee));
}
```

This caused:
1. Hook takes fee tokens from PoolManager → PoolManager balance decreases
2. Hook returns negative delta → PoolManager thinks it needs to give user less
3. PoolManager tries to transfer `fullAmount - fee` but already lost `fee` tokens
4. **Result**: PoolManager doesn't have enough tokens → arithmetic underflow

### First Attempted Fix (Incomplete)

Removed the `take()` call:

```solidity
// STILL WRONG
function afterSwap(...) {
    // Don't take tokens, just return delta
    hookDeltaUnspecified_ = -int128(int256(swapFee));  // Negative
}
```

**Result**: Tests still failed, but with a new error...

---

## Challenge 2: CurrencyNotSettled Error

### The Problem

```
Error: CurrencyNotSettled()
Tests now fail at the end of the unlock callback
PoolManager detects unsettled currency debts
```

All 8 previously failing tests now showed `CurrencyNotSettled` instead of arithmetic underflow.

### Root Cause

The sign of `hookDeltaUnspecified_` was backwards! From the IHooks documentation:

```solidity
/// @return int128 The hook's delta in unspecified currency
/// Positive: the hook is owed/took currency
/// Negative: the hook owes/sent currency
```

Using **negative delta** meant "hook owes currency to the pool", which is the opposite of what we wanted. The hook should **take** the fee, not owe it!

### The Fix

Changed from negative to positive:

```solidity
// CORRECT APPROACH (Part 1)
function afterSwap(...) {
    // Positive delta = hook took currency
    hookDeltaUnspecified_ = int128(int256(swapFee));  // Positive!
}
```

**Result**: Different error - still `CurrencyNotSettled`

### Why Still Failing?

When returning a **positive delta**, you're creating a debt in the PoolManager's accounting:
- "Hook claims to have taken X tokens"
- But the tokens are still sitting in the PoolManager!
- At unlock end: PoolManager checks if all debts are settled
- **Error**: Hook claimed tokens but never took them

---

## Challenge 3: Settling the Token Debt

### The Solution

You must **physically take the tokens** after claiming them via the positive delta:

```solidity
// CORRECT APPROACH (Final)
function afterSwap(...) returns (bytes4 selector_, int128 hookDeltaUnspecified_) {
    // Calculate fee
    uint256 swapFee = (absSwapAmount * FEE_BPS) / BPS_DENOMINATOR;

    // Track fees internally
    if (params.zeroForOne) {
        _poolFees[key.toId()].amount1 += swapFee;
    } else {
        _poolFees[key.toId()].amount0 += swapFee;
    }

    // Step 1: Claim the fee via positive delta
    // This reduces user's output and marks the tokens for the hook
    hookDeltaUnspecified_ = int128(int256(swapFee));  // POSITIVE

    // Step 2: Settle the debt by actually taking the tokens
    swapFeeCurrency.take(poolManager, address(this), swapFee, false);

    // Optional: Distribute accumulated fees
    _distributeFees(key);

    selector_ = IHooks.afterSwap.selector;
}
```

### The Flow

1. **User swaps**: 1 ETH → ~30 TOKEN
2. **Hook claims fee**: Returns positive delta of 0.3 TOKEN
3. **PoolManager accounts**:
   - User gets: 29.7 TOKEN (30 - 0.3)
   - Hook claimed: 0.3 TOKEN (debt created)
4. **Hook settles debt**: Calls `take()` to move 0.3 TOKEN to hook contract
5. **Unlock completes**: All debts settled ✅

---

## Key Learnings

### 1. Delta Sign Semantics

| Return Value | Meaning | Effect |
|-------------|---------|--------|
| Positive `+X` | Hook took X tokens | Reduces user output by X |
| Negative `-X` | Hook sent X tokens | Increases user output by X |
| Zero `0` | No change | Standard swap proceeds |

### 2. Delta vs Physical Transfers

- **Returning a delta** = declaring intent to take/send tokens
- **Calling take/settle** = actually moving the tokens
- **Both are required** when claiming tokens via positive delta

### 3. Settlement Requirements

Before the unlock callback completes, **all currency debts must be settled**:
- If hook returns positive delta → must call `take()`
- If hook returns negative delta → must call `settle()`
- If debt not settled → `CurrencyNotSettled` error

### 4. Why Not Just Use take() Without Delta?

You need **both**:
- **Delta return**: Tells PoolManager to adjust user's amounts
- **take() call**: Moves tokens to settle the accounting

Without the delta, the user would still get the full swap amount.

---

## Impact on _distributeFees

The fix also required updating the fee distribution function:

```solidity
// BEFORE (Wrong - tokens still in PoolManager)
function _distributeFees(PoolKey calldata _poolKey) internal {
    // Take tokens from PoolManager
    _poolKey.currency0.take(poolManager, address(this), donateAmount, false);

    // Donate to LPs
    poolManager.donate(_poolKey, donateAmount, 0, "");

    // Settle donation
    _poolKey.currency0.settle(poolManager, address(this), donateAmount, false);
}

// AFTER (Correct - tokens already in hook from afterSwap)
function _distributeFees(PoolKey calldata _poolKey) internal {
    // Tokens already in hook contract!

    // Donate to LPs
    poolManager.donate(_poolKey, donateAmount, 0, "");

    // Settle donation
    _poolKey.currency0.settle(poolManager, address(this), donateAmount, false);
}
```

---

## Debugging Process

### Tools Used

1. **Forge Test Verbosity**:
   ```bash
   forge test --match-test test_BasicSwap_NoInternalPool -vvvv
   ```
   This showed the exact call trace and where failures occurred.

2. **Error Code Analysis**:
   - `0x11` = Panic(17) = Arithmetic overflow/underflow
   - `CurrencyNotSettled()` = Custom error from PoolManager

3. **Balance Tracking**:
   Traced PoolManager balances before/after each operation to find discrepancies.

### Iteration Process

1. **Iteration 1**: Removed `take()` → Still failed (different error)
2. **Iteration 2**: Fixed delta sign → Still failed (CurrencyNotSettled)
3. **Iteration 3**: Added `take()` back → **SUCCESS!** ✅

---

## Conclusion

The `afterSwap` function requires careful coordination between:
1. **Delta return values** (accounting layer)
2. **Physical token transfers** (settlement layer)

Getting either wrong causes the entire transaction to fail. The key insight is that in Uniswap V4's accounting system, **declaring intent** (via delta) and **fulfilling that intent** (via take/settle) are separate operations that must both be done correctly.

---

## References

- Uniswap V4 IHooks.sol interface documentation
- Error traces from forge test -vvvv
- v4-core PoolManager.sol implementation
- Community discussions on hookDelta semantics

---

**Lessons for Future Hook Developers**:

1. Always check the IHooks documentation for return value semantics
2. Use forge test -vvvv to trace token movements
3. Remember: positive delta = hook takes, negative delta = hook gives
4. Always settle debts created by non-zero deltas
5. Test with various swap directions and amounts
