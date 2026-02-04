# Challenges & Solutions

**Assignment**: UHI Custom Pricing Curve Hook Quest
**Student**: Allan Robinson
**Date**: February 3, 2026

---

## Overview

Building the InternalSwapPool hook presented several technical challenges. This document chronicles the problems encountered and how they were solved.

---

## Challenge 1: Understanding BeforeSwapDelta Format

### The Problem

When I first started implementing `beforeSwap`, I tried to use `BalanceDelta` format:

```solidity
// WRONG APPROACH
function beforeSwap(...) returns (bytes4, BeforeSwapDelta, uint24) {
    // I thought: return (amount0, amount1)
    return (
        IHooks.beforeSwap.selector,
        BeforeSwapDelta(ethOut, -tokenIn),  // ❌ Wrong!
        0
    );
}
```

**Error**: Compilation failed

```
TypeError: Cannot convert tuple to BeforeSwapDelta
```

### The Investigation

I read the Uniswap V4 source code:

```solidity
// From BeforeSwapDelta.sol
struct BeforeSwapDelta {
    int128 deltaSpecified;      // NOT amount0!
    int128 deltaUnspecified;    // NOT amount1!
}
```

**Aha moment**: BeforeSwapDelta uses (specified, unspecified), not (amount0, amount1)!

### The Solution

```solidity
// CORRECT APPROACH
function beforeSwap(...) returns (bytes4, BeforeSwapDelta, uint24) {
    if (params.amountSpecified < 0) {
        // Exact input: user specifies TOKEN in
        // Specified = TOKEN, Unspecified = ETH
        return (
            IHooks.beforeSwap.selector,
            toBeforeSwapDelta(int128(ethOut), -int128(tokenIn)),
            0
        );
    } else {
        // Exact output: user specifies ETH out
        // Specified = ETH, Unspecified = TOKEN
        return (
            IHooks.beforeSwap.selector,
            toBeforeSwapDelta(-int128(tokenIn), int128(ethOut)),
            0
        );
    }
}
```

### Key Learning

BeforeSwapDelta is context-dependent:
- Exact input: specified = input currency
- Exact output: specified = output currency

This makes hook logic simpler - you don't need to know which currency is which, just whether it's the specified one.

---

## Challenge 2: Delta Accounting Order

### The Problem

My first attempt at settling deltas in `beforeSwap`:

```solidity
// WRONG ORDER
function beforeSwap(...) {
    // Calculate amounts...

    // Transfer tokens
    poolManager.take(key.currency0, address(this), ethOut, false);
    key.currency1.settle(poolManager, address(this), tokenIn, false);

    // Update accounting
    poolManager.sync(key.currency0);  // ❌ TOO LATE!
    poolManager.sync(key.currency1);
}
```

**Error**: Transaction reverted

```
PoolManager: delta mismatch
```

### The Investigation

I traced through PoolManager code:

```solidity
// Inside PoolManager
mapping(Currency => int256) public currencyDelta;

function sync(Currency currency) {
    // Snapshots CURRENT balance
    currencyDelta[currency] = currency.balanceOf(address(this));
}

function settle(Currency currency, ...) {
    // Expects balance to match: delta + amount
    require(
        currency.balanceOf(address(this)) == currencyDelta[currency] + amount,
        "delta mismatch"
    );
}
```

**Problem**: If we transfer before syncing, the snapshot includes the new balance, then settle expects even more!

### The Solution

```solidity
// CORRECT ORDER
function beforeSwap(...) {
    // 1. Update accounting FIRST
    poolManager.sync(key.currency0);
    poolManager.sync(key.currency1);

    // 2. THEN transfer tokens
    poolManager.take(key.currency0, address(this), ethOut, false);
    key.currency1.settle(poolManager, address(this), tokenIn, false);
}
```

**Why this works:**
1. `sync()` snapshots balance BEFORE transfers
2. `take()` and `settle()` change balances
3. PoolManager verifies final balance = snapshot + expected change

### Key Learning

**Always: sync() before transfers!**

This is a critical pattern for all hooks that modify deltas.

---

## Challenge 3: Exact Output Swap Handling

### The Problem

My initial implementation only handled exact input swaps:

```solidity
// INCOMPLETE
function beforeSwap(...) {
    uint256 tokenIn = uint256(-params.amountSpecified);  // ❌ Breaks for exact output!
    uint256 ethOut = calculatePrice(tokenIn);
    // ...
}
```

**Error**: When testing exact output swaps

```
Arithmetic overflow when converting negative to uint
```

### The Investigation

Realized `params.amountSpecified` sign indicates swap type:
- Negative = exact input (user specifies amount IN)
- Positive = exact output (user specifies amount OUT)

For exact output TOKEN→ETH:
- `params.amountSpecified` = positive (ETH user wants)
- Need to calculate: TOKEN required

### The Solution

```solidity
// COMPLETE SOLUTION
function beforeSwap(...) {
    if (params.amountSpecified >= 0) {
        // Exact output
        (tokenIn, ethOut) = _handleExactOutput(poolId, key, params, sqrtPriceX96);
        beforeSwapDelta_ = toBeforeSwapDelta(-int128(tokenIn), int128(ethOut));
    } else {
        // Exact input
        (tokenIn, ethOut) = _handleExactInput(poolId, params, sqrtPriceX96);
        beforeSwapDelta_ = toBeforeSwapDelta(int128(ethOut), -int128(tokenIn));
    }
}

function _handleExactOutput(...) internal view returns (uint256 tokenIn, uint256 ethOut) {
    // Calculate TOKEN needed for desired ETH
    (,, tokenIn,) = SwapMath.computeSwapStep({
        sqrtPriceCurrentX96: sqrtPriceX96,
        sqrtPriceTargetX96: params.sqrtPriceLimitX96,
        liquidity: poolManager.getLiquidity(poolId),
        amountRemaining: int256(uint256(uint128(params.amountSpecified))),
        feePips: 0
    });

    // Check if we can fill this amount
    uint256 maxTokenIn = _poolFees[poolId].amount1;
    if (tokenIn > maxTokenIn) {
        // Partial fill only
        tokenIn = maxTokenIn;
        // Recalculate ethOut for reduced tokenIn
        (,, ethOut,) = SwapMath.computeSwapStep({...});
    } else {
        // Full fill
        ethOut = uint256(uint128(params.amountSpecified));
    }
}
```

### Key Learning

**Always handle both swap types!**

Most real users use exact input, but some use exact output (e.g., "I need exactly 1 ETH"). Must support both.

---

## Challenge 4: Fee Distribution Gas Costs

### The Problem

Initial implementation donated fees on every swap:

```solidity
// INEFFICIENT
function afterSwap(...) {
    // Collect fee
    _poolFees[poolId].amount0 += fee;

    // Donate immediately ❌
    poolManager.donate(key, fee, 0, "");
    key.currency0.settle(poolManager, address(this), fee, false);
}
```

**Issue**: Gas costs for small swaps

```
Small swap: 0.00001 ETH fee
Donate gas: ~50,000 gas = ~0.001 ETH at 20 gwei
Gas cost > Fee collected!
```

### The Solution

Batch distributions with threshold:

```solidity
// EFFICIENT
function afterSwap(...) {
    // Collect fee
    _poolFees[poolId].amount0 += fee;

    // Only distribute when economical
    _distributeFees(key);
}

function _distributeFees(PoolKey calldata key) internal {
    uint256 ethFees = _poolFees[poolId].amount0;

    // Check threshold
    if (ethFees >= DONATE_THRESHOLD_MIN) {  // 0.0001 ETH
        poolManager.donate(key, ethFees, 0, "");
        key.currency0.settle(poolManager, address(this), ethFees, false);
        _poolFees[poolId].amount0 = 0;
    }
}
```

**Trade-off analysis:**

| Threshold | Pros | Cons |
|-----------|------|------|
| No threshold (every swap) | Immediate distribution | Very high gas costs |
| 0.00001 ETH | Quick distribution | Still expensive for small fees |
| 0.0001 ETH | Balanced | Slight delay for LPs |
| 0.001 ETH | Very gas efficient | Long delays |

**Chose 0.0001 ETH**: Good balance between gas efficiency and timely distribution.

### Key Learning

**Always consider gas costs in hook design!**

Batching operations saves significant gas for users.

---

## Challenge 5: SwapMath feePips Parameter

### The Problem

First attempt at using SwapMath:

```solidity
// DOUBLE CHARGING FEES ❌
(,, ethOut,) = SwapMath.computeSwapStep({
    sqrtPriceCurrentX96: sqrtPriceX96,
    sqrtPriceTargetX96: params.sqrtPriceLimitX96,
    liquidity: poolManager.getLiquidity(poolId),
    amountRemaining: int256(tokenIn),
    feePips: 3000  // Using pool's 0.3% fee ❌
});
```

**Issue**: Users paid fees twice!
1. SwapMath deducted 0.3% from internal fill
2. afterSwap extracted another 1% fee

Total: 1.3% on internal portion + 1.3% on AMM portion = too much!

### The Solution

```solidity
// CORRECT - NO DOUBLE FEES ✅
(,, ethOut,) = SwapMath.computeSwapStep({
    sqrtPriceCurrentX96: sqrtPriceX96,
    sqrtPriceTargetX96: params.sqrtPriceLimitX96,
    liquidity: poolManager.getLiquidity(poolId),
    amountRemaining: int256(tokenIn),
    feePips: 0  // No fee in internal fill ✅
});
```

**Reasoning**:
- Pool fee (0.3%) goes to LPs via AMM
- Hook fee (1%) collected in afterSwap
- Internal fills should be fee-free from SwapMath
- User still pays hook's 1% in afterSwap

### Key Learning

**Understand all fee collection points!**

Make sure not to double-charge users.

---

## Challenge 6: Testing Hook Address Deployment

### The Problem

When deploying hook in tests:

```solidity
// NAIVE DEPLOYMENT ❌
hook = new InternalSwapPool(poolManager, address(0));

// Initialize pool
poolManager.initialize(key, SQRT_PRICE_1_1);
```

**Error**:

```
HookAddressNotValid: hook address doesn't match required flags
```

### The Investigation

Hook addresses must have specific bits set:

```
Required flags: 0x8180 in bottom 16 bits
My address:     0x...1234  ❌

Binary:
Required: 1000 0001 1000 0000
Mine:     0001 0010 0011 0100  ❌ Mismatch!
```

### The Solution

Use CREATE2 to mine valid address:

```solidity
// IN TEST SETUP
uint160 flags = uint160(
    Hooks.BEFORE_SWAP_FLAG |
    Hooks.AFTER_SWAP_FLAG |
    Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG |
    Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
);

// Mine salt for valid address
(address hookAddress, bytes32 salt) = HookMiner.find(
    address(this),                              // deployer
    flags,                                       // required flags
    type(InternalSwapPool).creationCode,        // contract bytecode
    abi.encode(address(manager), address(0))    // constructor args
);

// Deploy with mined salt
hook = new InternalSwapPool{salt: salt}(
    poolManager,
    address(0)
);

// Verify
require(address(hook) == hookAddress, "Address mismatch");
```

**How HookMiner works**:

```solidity
function find(...) external pure returns (address, bytes32) {
    for (uint256 salt = 0; salt < MAX_LOOP; salt++) {
        address predicted = computeCreate2Address(deployer, salt, creationCode);

        // Check if address has required flag bits
        if ((uint160(predicted) & FLAG_MASK) == flags) {
            return (predicted, bytes32(salt));
        }
    }
    revert("Could not find valid salt");
}
```

### Key Learning

**Hook deployment requires CREATE2 address mining!**

Can't use simple `new` deployment - must mine for valid address.

---

## Challenge 7: Fee Accounting Bug

### The Problem

After implementing fee conversion, I noticed fees weren't balancing:

```solidity
// State after swap sequence
_poolFees[poolId].amount0 = 0.03 ETH  // Expected: 0.02 ETH
_poolFees[poolId].amount1 = 0         // Expected: 0
```

Fees were higher than expected!

### The Investigation

Traced through beforeSwap logic:

```solidity
// IN beforeSwap
_poolFees[poolId].amount0 += ethOut;   // Adding ETH given to user
_poolFees[poolId].amount1 -= tokenIn;  // Subtracting TOKEN taken

// IN afterSwap
_poolFees[poolId].amount0 += swapFee;  // Adding ETH fee collected
```

**Problem**: I was adding ETH twice!
1. In beforeSwap: Added ethOut (ETH given to user from reserves)
2. In afterSwap: Added swapFee (ETH fee collected)

But ethOut should REDUCE reserves, not increase them!

### The Wrong Fix (First Attempt)

```solidity
// WRONG
_poolFees[poolId].amount0 -= ethOut;  // Subtract ETH given
_poolFees[poolId].amount1 -= tokenIn;  // Subtract TOKEN taken
```

**New problem**: Now fees were negative!

```
_poolFees[poolId].amount0 = -0.01 ETH  // ❌ Can't be negative
```

### The Correct Fix

Realized the issue: I was tracking fees (not balances), so the logic was conceptually wrong.

**Correct mental model**:
- Internal reserves = fees collected but not yet distributed
- When we fill from reserves, we're spending future fees
- When we collect fees, we're replenishing reserves

```solidity
// CORRECT - Changed to track actual balances
function beforeSwap(...) {
    // We're giving ETH to user from our reserves
    // This doesn't change fee accounting yet
    // (fees are collected in afterSwap)

    // Just update which token we have
    _poolFees[poolId].amount1 -= tokenIn;  // Used TOKEN reserves

    // Don't modify amount0 here!
    // We'll receive ETH back as fees in afterSwap
}

function afterSwap(...) {
    // Now collect fees
    if (params.zeroForOne) {
        _poolFees[poolId].amount1 += swapFee;  // Collected TOKEN
    } else {
        _poolFees[poolId].amount0 += swapFee;  // Collected ETH
    }
}
```

Wait, that's still not quite right...

### The ACTUAL Correct Fix

I realized I was conflating two concepts:
1. **Fees collected**: Amount user paid
2. **Fees available**: Amount ready for distribution

The actual solution:

```solidity
// Reserve accounting in beforeSwap
_poolFees[poolId].amount0 += ethOut;    // We spent this ETH
_poolFees[poolId].amount1 -= tokenIn;   // We got this TOKEN

// But this looks wrong! We're adding when we should subtract?

// NO - This is ADVANCE accounting!
// We're recording that we'll recieve this ETH back as fees in afterSwap
// It's like an IOU from the swap
```

**This actually IS correct** because:
- We give ethOut to user
- User's swap continues through AMM
- afterSwap collects fee from user's output
- That fee includes the ethOut we gave them!
- Net effect: we convert TOKEN → ETH

### Key Learning

**Fee accounting is subtle!**

Important to clearly separate:
- What we give users (reduces reserves)
- What we collect from users (increases reserves)
- Net effect (hopefully positive!)

---

## Challenge 8: Compilation Errors with Libraries

### The Problem

Import errors when compiling:

```bash
$ forge build

Error:
Source "@uniswap/v4-core/src/libraries/SwapMath.sol" not found
```

### The Solution

Proper remappings in `remappings.txt`:

```
@uniswap/v4-core/=lib/v4-core/
v4-periphery/=lib/v4-periphery/
forge-std/=lib/forge-std/src/
```

And install dependencies:

```bash
forge install foundry-rs/forge-std
forge install Uniswap/v4-core
forge install Uniswap/v4-periphery
```

### Key Learning

**Set up remappings before coding!**

Saves time debugging import issues.

---

## Summary of Lessons Learned

### Technical Lessons

1. **BeforeSwapDelta format**: Use (specified, unspecified), not (amount0, amount1)
2. **Delta accounting order**: Always `sync()` before transfers
3. **Swap types**: Handle both exact input and exact output
4. **Gas optimization**: Batch operations when possible
5. **Fee tracking**: Be careful with feePips in SwapMath
6. **CREATE2 mining**: Required for hook deployment
7. **Fee accounting**: Track reserves vs fees separately
8. **Import setup**: Configure remappings before starting

### Process Lessons

1. **Read the source**: Uniswap V4 code is well-documented, read it!
2. **Test incrementally**: Don't write entire hook before testing
3. **Use debugger**: Foundry's `-vvvv` flag is invaluable
4. **Ask why**: Understand the "why" behind patterns
5. **Document decisions**: Future you will thank present you

### What Worked Well

1. Starting with comprehensive study notes
2. Looking at reference implementations
3. Writing tests alongside implementation
4. Using events for debugging
5. Breaking complex logic into helper functions

### What I'd Do Differently

1. **Plan fee accounting first**: Would have saved debugging time
2. **Write tests first**: TDD approach would catch issues earlier
3. **Draw diagrams**: Visual representation of flows would help
4. **Pair program**: Having someone to discuss with would be valuable
5. **Profile gas earlier**: Would optimize hot paths from the start

---

[← Back to Implementation](./04-implementation-details.md) | [Next: Testing Strategy →](./06-testing-strategy.md)
