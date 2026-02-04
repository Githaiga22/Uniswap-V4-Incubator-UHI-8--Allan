# Learning Outcomes

**Assignment**: UHI Custom Pricing Curve Hook Quest
**Student**: Allan Robinson
**Date**: February 3, 2026

---

## Overview

This document outlines the key concepts learned while building the InternalSwapPool hook for Week 3 of the Uniswap V4 Hooks Incubator program.

---

## Core Concepts Learned

### 1. Return Delta Hooks (NoOp Hooks)

**What Are NoOp Hooks?**

NoOp (No Operation) hooks are a special type of hook that can bypass or modify Uniswap's core AMM swap logic. They achieve this by:
- Returning delta values that modify `amountToSwap`
- Filling swaps partially or completely from external sources
- Creating custom pricing curves independent of the AMM

**The Four Return Delta Hook Types:**

```solidity
// 1. beforeSwapReturnDelta - Modify input before core swap
function beforeSwap(...) returns (bytes4, BeforeSwapDelta, uint24)

// 2. afterSwapReturnDelta - Extract fees from output
function afterSwap(...) returns (bytes4, int128)

// 3. afterAddLiquidityReturnDelta - Modify LP tokens minted
function afterAddLiquidity(...) returns (bytes4, BalanceDelta)

// 4. afterRemoveLiquidityReturnDelta - Modify tokens returned
function afterRemoveLiquidity(...) returns (bytes4, BalanceDelta)
```

**Key Learning**: NoOp hooks enable building orderbooks, custom pricing curves, and fee structures on top of Uniswap without forking the protocol.

---

### 2. BeforeSwapDelta vs BalanceDelta

**Understanding the Difference:**

```solidity
// BalanceDelta - Used in most hooks
// Format: (amount0, amount1)
// Always clear which token is which
struct BalanceDelta {
    int256 amount0;  // Currency0 delta
    int256 amount1;  // Currency1 delta
}

// BeforeSwapDelta - Used only in beforeSwap
// Format: (specified, unspecified)
// Changes based on swap direction!
struct BeforeSwapDelta {
    int128 deltaSpecified;    // The token user is selling/buying
    int128 deltaUnspecified;  // The token user receives/provides
}
```

**Why BeforeSwapDelta Uses (Specified, Unspecified)?**

Because swap direction determines which token is which:

```
Example 1: Exact Input Swap (ETH → TOKEN)
├─ zeroForOne = true
├─ amountSpecified = -1 ether (negative = exact input)
├─ Specified token = currency0 (ETH)
├─ Unspecified token = currency1 (TOKEN)
└─ BeforeSwapDelta = (ETH delta, TOKEN delta)

Example 2: Exact Output Swap (TOKEN → ETH)
├─ zeroForOne = false
├─ amountSpecified = 1 ether (positive = exact output)
├─ Specified token = currency0 (ETH) - what user wants OUT
├─ Unspecified token = currency1 (TOKEN) - what user puts IN
└─ BeforeSwapDelta = (ETH delta, TOKEN delta)
```

**Key Learning**: BeforeSwapDelta's (specified, unspecified) format adapts to swap direction, making hook logic simpler when you don't care about token order.

---

### 3. How amountToSwap Modification Works

**The Magic Formula:**

```solidity
// Inside PoolManager.swap() - pseudocode
int256 amountToSwap = params.amountSpecified;

if (hasBeforeSwapReturnDelta) {
    BeforeSwapDelta delta = hook.beforeSwap(...);

    // THIS IS THE KEY LINE:
    amountToSwap += delta.deltaSpecified;

    // If hook fills entire swap:
    // amountToSwap = -100 (user wants to sell 100 TOKEN)
    // delta.deltaSpecified = 100 (hook takes 100 TOKEN)
    // amountToSwap = -100 + 100 = 0 (nothing left for AMM!)
}

// Swap remaining amount through AMM
if (amountToSwap != 0) {
    // Execute AMM swap logic...
}
```

**Three NoOp Scenarios:**

```
1. Full NoOp (Complete Bypass):
   ├─ Hook fills entire swap amount
   ├─ amountToSwap becomes 0
   └─ AMM never executes

2. Partial NoOp:
   ├─ Hook fills portion of swap
   ├─ amountToSwap reduced but not 0
   └─ AMM fills remainder

3. No NoOp (Normal Swap):
   ├─ Hook returns zero delta
   ├─ amountToSwap unchanged
   └─ AMM handles entire swap
```

**Key Learning**: By returning strategic delta values, hooks can control exactly how much of a swap goes through the AMM vs custom logic.

---

### 4. Internal Orderbook Pattern

**What I Built:**

An internal orderbook that sits on top of Uniswap's AMM pool:

```
Traditional Uniswap:
User → PoolManager → AMM Swap → Output to User

With Internal Orderbook Hook:
User → PoolManager → Hook (fill from reserves) → AMM (fill remainder) → Output to User
```

**How It Works:**

```solidity
// Step 1: Accumulate TOKEN fees from buy swaps
afterSwap(ETH → TOKEN swap) {
    fee = output * 1%
    internalReserves.TOKEN += fee  // Store TOKEN
}

// Step 2: When someone sells TOKEN, fill from internal reserves
beforeSwap(TOKEN → ETH swap) {
    if (internalReserves.TOKEN > 0) {
        // Calculate how much we can fill
        uint256 ethToGive = calculatePrice(amountIn)

        // Return delta to modify amountToSwap
        return BeforeSwapDelta({
            deltaSpecified: amountIn,      // Take their TOKEN
            deltaUnspecified: -ethToGive   // Give them ETH
        })
    }
}
```

**Benefits of Internal Orderbook:**

1. **Zero Price Impact**: Internal fills don't move pool price
2. **Fee Conversion**: Convert TOKEN fees to ETH fees transparently
3. **Gas Efficient**: Uses current price, no expensive AMM calculations
4. **Trustless**: All logic on-chain, atomic settlement

**Key Learning**: Hooks can maintain state (reserves, positions, orders) and use it to create sophisticated trading mechanisms without modifying core Uniswap logic.

---

### 5. Delta Accounting System

**The Critical Pattern: sync() before settle()**

```solidity
// WRONG - Will revert!
function beforeSwap() {
    key.currency0.settle(poolManager, address(this), amount, false);
    poolManager.sync(key.currency0);  // TOO LATE!
}

// CORRECT
function beforeSwap() {
    // 1. Update state first
    poolManager.sync(key.currency0);

    // 2. Then transfer tokens
    key.currency0.settle(poolManager, address(this), amount, false);
}
```

**Why This Order Matters:**

The PoolManager tracks deltas for each currency:

```solidity
// Inside PoolManager
mapping(Currency => int256) public currencyDelta;

function sync(Currency currency) {
    // Snapshot current balance
    currencyDelta[currency] = currency.balanceOf(address(this));
}

function settle(Currency currency, address payer, uint256 amount) {
    // Expected: balanceOf should equal delta + amount
    require(
        currency.balanceOf(address(this)) == currencyDelta[currency] + amount,
        "Delta mismatch"
    );
}
```

**Three Key Functions:**

1. **sync()**: Update internal accounting before state changes
2. **take()**: Hook receives tokens from PoolManager
3. **settle()**: Hook sends tokens to PoolManager

**Key Learning**: Delta accounting ensures atomic settlement - either entire swap succeeds or entire swap reverts. No partial failures possible.

---

### 6. SwapMath Library for Fair Pricing

**Problem**: How do I price internal swaps fairly?

**Solution**: Use Uniswap's own SwapMath library:

```solidity
import {SwapMath} from "@uniswap/v4-core/src/libraries/SwapMath.sol";

function calculateInternalSwap(uint256 tokenIn) internal view returns (uint256 ethOut) {
    (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);
    uint128 liquidity = poolManager.getLiquidity(poolId);

    // Use same math as AMM
    (sqrtPriceX96, , ethOut, ) = SwapMath.computeSwapStep({
        sqrtPriceCurrentX96: sqrtPriceX96,
        sqrtPriceTargetX96: params.sqrtPriceLimitX96,
        liquidity: liquidity,
        amountRemaining: int256(tokenIn),
        feePips: 0  // No fee for internal fills
    });

    return ethOut;
}
```

**What This Does:**

- Uses current pool price (sqrtPriceX96)
- Uses current pool liquidity
- Calculates exact output amount
- Zero fees for internal swaps (fees already collected in afterSwap)

**Key Learning**: Always use battle-tested math libraries. Don't invent your own pricing formulas.

---

### 7. Hook Address Mining (CREATE2)

**The Problem**: Hook addresses must have specific bit flags

```solidity
// My hook needs these permissions
uint160 flags = uint160(
    Hooks.BEFORE_SWAP_FLAG |               // Bit 7
    Hooks.AFTER_SWAP_FLAG |                // Bit 8
    Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG | // Bit 14
    Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG    // Bit 15
);

// Address must have these bits set in bottom 16 bits
// Example: 0x...00008180
```

**The Solution**: Mine salt values with CREATE2

```solidity
function findSalt() {
    for (uint256 salt = 0; salt < MAX_ITERATIONS; salt++) {
        address predicted = computeCreate2Address(
            deployer,
            salt,
            keccak256(creationCodeWithArgs)
        );

        if ((uint160(predicted) & FLAG_MASK) == flags) {
            return salt;  // Found valid address!
        }
    }
}
```

**Key Learning**: CREATE2 deployment is deterministic, allowing us to search for addresses with specific properties by trying different salt values.

---

### 8. Exact Input vs Exact Output Swaps

**Understanding the User's Intent:**

```solidity
// Exact Input: User specifies how much they're SELLING
// amountSpecified is NEGATIVE
zeroForOne: true
amountSpecified: -100 ether
Meaning: "Sell exactly 100 ETH, give me whatever TOKEN I get"

// Exact Output: User specifies how much they're BUYING
// amountSpecified is POSITIVE
zeroForOne: true
amountSpecified: 100 ether
Meaning: "I want exactly 100 TOKEN, take whatever ETH you need"
```

**Handling Both in beforeSwap:**

```solidity
function beforeSwap(...) {
    if (params.amountSpecified < 0) {
        // Exact Input - user knows input amount
        return _handleExactInput(...);
    } else {
        // Exact Output - user knows output amount
        return _handleExactOutput(...);
    }
}
```

**Key Learning**: Sign of amountSpecified (+/-) indicates exact input vs exact output, not swap direction. Swap direction is determined by `zeroForOne`.

---

### 9. Fee Distribution via donate()

**Traditional LP Fees**: Collected in both tokens, LPs must sell to realize profit

**Hook-Controlled Fees**: Route all fees to single token

```solidity
function _distributeFees(PoolKey calldata key) internal {
    PoolId poolId = key.toId();
    uint256 ethFees = _poolFees[poolId].amount0;

    if (ethFees >= DONATE_THRESHOLD_MIN) {
        // Give fees to LPs in their proportional share
        poolManager.donate(
            key,
            ethFees,  // amount0 (ETH)
            0,        // amount1 (TOKEN) - zero!
            ""
        );

        // Settle the donation
        key.currency0.settle(poolManager, address(this), ethFees, false);

        _poolFees[poolId].amount0 = 0;
    }
}
```

**What donate() Does:**

- Adds tokens directly to pool reserves
- Increases all LP positions proportionally
- No price impact
- No gas for LPs to claim

**Key Learning**: donate() enables custom fee distribution strategies without requiring LPs to manually claim or sell tokens.

---

## Key Takeaways

### Technical Skills Gained

1. ✅ Implementing Return Delta hooks (beforeSwapReturnDelta, afterSwapReturnDelta)
2. ✅ Understanding BeforeSwapDelta format and when to use it
3. ✅ Manipulating amountToSwap for partial/complete NoOps
4. ✅ Delta accounting with sync(), take(), settle()
5. ✅ Using SwapMath library for fair pricing
6. ✅ CREATE2 address mining for hook deployment
7. ✅ Handling both exact input and exact output swaps
8. ✅ Using donate() for custom fee distribution

### Architectural Understanding

1. **Separation of Concerns**: Hooks handle custom logic, AMM handles price discovery
2. **Composability**: Internal orderbook + AMM = hybrid model
3. **State Management**: Hooks can maintain reserves, positions, orders
4. **Atomic Settlement**: Delta accounting prevents partial failures

### Real-World Problem Solving

**Problem**: Token launchpad LPs must sell token to realize profit, creating downward pressure

**Solution Components**:
1. Capture TOKEN fees from buy swaps (afterSwap)
2. Convert TOKEN fees to ETH by filling sell swaps (beforeSwap)
3. Distribute only ETH fees to LPs (donate)
4. Zero selling pressure on TOKEN price

**Result**: Aligned incentives - LPs and token holders both want price to increase

---

## Next Steps

### Areas for Deeper Study

1. **Concentrated Liquidity Integration**: Use Uniswap positions instead of flat reserves
2. **Multi-Hook Coordination**: How do multiple hooks interact on same pool?
3. **MEV Considerations**: Can hook logic be sandwiched or front-run?
4. **Gas Optimization**: Profile and optimize hot paths
5. **Dynamic Fee Structures**: Fees based on volatility, volume, or time

### Application Ideas

1. **Launchpad Platform**: Deploy this hook for all new token launches
2. **Treasury Management**: DAO-controlled internal reserves
3. **Liquidity Mining**: Reward users who add to internal reserves
4. **NFT Floor Price**: Similar concept for NFT-backed pools

---

[← Back to Overview](./01-assignment-overview.md) | [Next: Hook Design →](./03-hook-design.md)
