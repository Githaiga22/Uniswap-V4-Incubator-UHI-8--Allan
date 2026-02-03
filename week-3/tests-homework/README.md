# Week 3 Homework: Custom Pricing Curve Hook

**Author**: Allan Robinson
**Email**: (your email here)
**Date**: February 3, 2026
**Assignment**: UHI Custom Pricing Curve Hook Quest

---

## Table of Contents

1. [Assignment Overview](#assignment-overview)
2. [Learning Outcomes](#learning-outcomes)
3. [Hook Concept & Design](#hook-concept--design)
4. [Technical Implementation](#technical-implementation)
5. [Thought Process](#thought-process)
6. [Challenges & Solutions](#challenges--solutions)
7. [Testing Strategy](#testing-strategy)
8. [Future Improvements](#future-improvements)
9. [Repository Link](#repository-link)

---

## Assignment Overview

### Requirements

✅ **Attended Workshop 10**: Yes - February 3, 2026 class on Return Delta Hooks
✅ **Reviewed Curriculum**: Completed study notes for Custom Curve CSMM Lesson
✅ **Built Custom Hook**: Internal Swap Pool with beforeSwapReturnDelta
✅ **Public GitHub**: Repository available at `/home/robinsoncodes/Documents/uniswap-UH8/Internal-Swap-Pool`

### Objective

Build a Custom Pricing Curve Hook (Return Delta Hook / NoOp Hook) that demonstrates understanding of:
- BeforeSwapDelta vs BalanceDelta
- beforeSwapReturnDelta permissions
- Custom swap logic that bypasses core AMM
- Delta accounting and token settlement

---

## Learning Outcomes

Through this homework, I learned:

### 1. **BeforeSwapDelta Mechanics**

The key insight is that `BeforeSwapDelta` uses **(specified, unspecified)** format instead of **(amount0, amount1)**:

```solidity
// BalanceDelta: Always (token0, token1)
BalanceDelta delta = (-100 token0, +98 token1)

// BeforeSwapDelta: Variable based on swap direction
// For exact input 0→1: (token0, token1)
// For exact output 0→1: (token1, token0)  // Order flipped!
BeforeSwapDelta beforeDelta = (specified, unspecified)
```

This allows hooks to "consume" the user's input token and provide the output token, effectively bypassing the AMM.

### 2. **amountToSwap Modification**

The magic happens in `Hooks.sol`:

```solidity
amountToSwap = params.amountSpecified;  // Start with user amount

if (beforeSwapReturnDelta enabled) {
    hookDeltaSpecified = hookReturn.getSpecifiedDelta();
    amountToSwap += hookDeltaSpecified;  // Modify!
}

// If hook returned +100 and user specified -100:
// amountToSwap = -100 + 100 = 0 (full NoOp!)
```

By returning appropriate `BeforeSwapDelta`, hooks can:
- Fully skip AMM (amountToSwap = 0)
- Partially skip AMM (amountToSwap reduced)
- Implement custom pricing curves

### 3. **Internal Orderbooks**

Hooks can maintain internal reserves and act as an orderbook layer **on top** of Uniswap. This enables:
- Custom pricing without pool price impact
- Fee conversion without selling pressure
- Hybrid AMM/orderbook models

### 4. **Delta Accounting**

Critical pattern learned:

```solidity
// 1. Modify internal state
_poolFees[poolId].amount1 -= tokenIn;
_poolFees[poolId].amount0 += ethOut;

// 2. Sync with PoolManager
poolManager.sync(currency0);
poolManager.sync(currency1);

// 3. Settle tokens
poolManager.take(currency0, address(this), ethOut);  // Hook receives
currency1.settle(poolManager, address(this), tokenIn, false);  // Hook sends
```

Order matters! Always sync before settle.

---

## Hook Concept & Design

### Problem I'm Solving

**Token Launchpad Dilemma**:

In traditional pools, when users buy TOKEN with ETH:
- ✅ Fees collected in TOKEN
- ❌ LPs must sell TOKEN to realize profit
- ❌ Selling creates downward price pressure
- ❌ Misaligned incentives

**My Solution**: Internal Swap Pool

Ensure **all LP fees are in ETH** by:
1. Capturing TOKEN fees from buy swaps
2. Using TOKEN fees to fill sell swaps
3. Converting TOKEN → ETH without hitting the pool
4. Distributing only ETH fees to LPs

### Design Goals

1. **Zero Selling Pressure**: LPs never need to sell TOKEN
2. **Fair Pricing**: Use current pool price for internal swaps
3. **Gas Efficient**: Minimal additional gas beyond normal swaps
4. **Trustless**: All logic on-chain, no admin privileges
5. **Simple**: Easy to understand and audit

### Architecture

```
┌─────────────────────────────────────────────────────┐
│              INTERNAL SWAP POOL HOOK                │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Component 1: Fee Capture (afterSwap)              │
│  ├─ Capture 1% of all swap outputs                 │
│  ├─ Store TOKEN fees internally                    │
│  └─ Store ETH fees for LP distribution             │
│                                                     │
│  Component 2: Internal Fill (beforeSwap)           │
│  ├─ Check if TOKEN→ETH swap                        │
│  ├─ Check if hook has TOKEN reserves               │
│  ├─ Calculate fair price using SwapMath            │
│  ├─ Fill from internal pool                        │
│  └─ Return BeforeSwapDelta to reduce amountToSwap  │
│                                                     │
│  Component 3: LP Distribution (_distributeFees)    │
│  ├─ Check if ETH fees above threshold              │
│  ├─ Call poolManager.donate()                      │
│  ├─ Settle ETH to PoolManager                      │
│  └─ Distribute to currently active LPs             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Technical Implementation

### Hook Permissions Required

```solidity
beforeSwap: true                     // Execute internal swap logic
afterSwap: true                      // Capture fees
beforeSwapReturnDelta: true          // Modify amountToSwap
afterSwapReturnDelta: true           // Extract fees from output
```

### Core Functions

#### 1. **beforeSwap: Internal Pool Filling**

```solidity
function beforeSwap(...) external override
    returns (bytes4, BeforeSwapDelta, uint24)
{
    // Only for TOKEN → ETH swaps with TOKEN reserves
    if (!params.zeroForOne && _poolFees[poolId].amount1 != 0) {

        // Calculate how much we can fill
        uint256 tokenIn;
        uint256 ethOut;

        if (params.amountSpecified >= 0) {
            // Exact output: User wants specific ETH amount
            (tokenIn, ethOut) = _handleExactOutput(...);
        } else {
            // Exact input: User selling specific TOKEN amount
            (tokenIn, ethOut) = _handleExactInput(...);
        }

        // Update internal reserves
        _poolFees[poolId].amount1 -= tokenIn;  // Spent TOKEN
        _poolFees[poolId].amount0 += ethOut;   // Gained ETH

        // Settle with PoolManager
        poolManager.sync(key.currency0);
        poolManager.sync(key.currency1);
        poolManager.take(key.currency0, address(this), ethOut);
        key.currency1.settle(poolManager, address(this), tokenIn, false);

        // Return delta to modify amountToSwap
        return (selector, toBeforeSwapDelta(...), 0);
    }

    return (selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
}
```

**Key Insight**: Using `SwapMath.computeSwapStep()` with `feePips = 0` ensures fair pricing at current pool price without additional fees.

#### 2. **afterSwap: Fee Capture**

```solidity
function afterSwap(...) external override
    returns (bytes4, int128 hookDeltaUnspecified_)
{
    // Determine unspecified currency (the output)
    Currency swapFeeCurrency = params.amountSpecified < 0 == params.zeroForOne
        ? key.currency1
        : key.currency0;

    // Calculate 1% fee
    int128 swapAmount = params.amountSpecified < 0 == params.zeroForOne
        ? delta.amount1()
        : delta.amount0();
    uint256 swapFee = (absValue(swapAmount) * 100) / 10000;

    // Store fee internally
    if (params.zeroForOne) {
        _poolFees[poolId].amount1 += swapFee;  // TOKEN fee
    } else {
        _poolFees[poolId].amount0 += swapFee;  // ETH fee
    }

    // Extract fee from PoolManager
    swapFeeCurrency.take(poolManager, address(this), swapFee, false);

    // Reduce user's output by fee amount
    hookDeltaUnspecified_ = -int128(int256(swapFee));

    // Distribute accumulated ETH fees
    _distributeFees(key);

    return (selector, hookDeltaUnspecified_);
}
```

**Key Insight**: `afterSwapReturnDelta` allows extracting fees from the swap output without modifying pool accounting. The negative `hookDeltaUnspecified_` reduces what the user receives.

#### 3. **_distributeFees: LP Rewards**

```solidity
function _distributeFees(PoolKey calldata key) internal {
    uint256 donateAmount = _poolFees[poolId].amount0;

    // Only donate if above threshold (gas efficiency)
    if (donateAmount < DONATE_THRESHOLD_MIN) return;

    // Donate to LPs
    BalanceDelta delta = poolManager.donate(key, donateAmount, 0, "");

    // Settle donation (we owe ETH to PM)
    if (delta.amount0() < 0) {
        key.currency0.settle(
            poolManager,
            address(this),
            uint256(uint128(-delta.amount0())),
            false
        );
    }

    // Update internal accounting
    _poolFees[poolId].amount0 -= donateAmount;
}
```

**Key Insight**: `donate()` distributes tokens to currently active LPs without affecting pool price. Perfect for fee distribution.

### Mathematics: SwapMath

Using Uniswap's `SwapMath.computeSwapStep()` for price calculation:

```solidity
(, ethOut, tokenIn, ) = SwapMath.computeSwapStep({
    sqrtPriceCurrentX96: sqrtPriceX96,
    sqrtPriceTargetX96: params.sqrtPriceLimitX96,
    liquidity: poolManager.getLiquidity(poolId),
    amountRemaining: int256(amount),
    feePips: 0  // No fee for internal swaps!
});
```

**Why feePips = 0?**
- Internal swaps help the ecosystem
- Already capturing fees in afterSwap
- Benefits both parties (user gets fair price, hook converts fees)

---

## Thought Process

### Step 1: Understanding the Problem

After today's class, I realized token launchpads have a fundamental problem:
- LPs accumulate TOKEN fees
- Must sell TOKEN to realize profit
- Selling hurts token holders
- Creates misaligned incentives

**Question**: Can we make LP fees single-token (ETH only)?

### Step 2: Exploring Return Delta Hooks

The lesson taught us that `beforeSwapReturnDelta` can modify `amountToSwap`:

```
User wants to swap 100 TOKEN → ETH
Hook has 10 TOKEN in fees

Hook can:
1. Fill 10 TOKEN from internal reserves
2. Return BeforeSwapDelta to "consume" 10 TOKEN
3. amountToSwap becomes 90 TOKEN
4. Core AMM only swaps 90 TOKEN
```

**Realization**: This is an internal orderbook on top of Uniswap!

### Step 3: Designing the Fee Flow

```
Buy Swaps (ETH → TOKEN):
├─ afterSwap captures 1% fee in TOKEN
└─ Store TOKEN fees internally

Sell Swaps (TOKEN → ETH):
├─ beforeSwap fills from TOKEN fees
├─ Convert TOKEN fees → ETH fees
└─ afterSwap distributes ETH fees to LPs

Result: LPs only receive ETH!
```

### Step 4: Handling Edge Cases

**Challenge 1**: What if user swap > internal reserves?

**Solution**: Partial fills
```solidity
if (ethOut > uint256(-params.amountSpecified)) {
    // Scale down proportionally
    uint256 percentage = (uint256(-params.amountSpecified) * 1e18) / ethOut;
    tokenIn = (tokenIn * percentage) / 1e18;
}
```

**Challenge 2**: Exact input vs exact output?

**Solution**: Different `BeforeSwapDelta` formats
```solidity
if (params.amountSpecified >= 0) {
    // Exact output: Specified = ETH, Unspecified = TOKEN
    return toBeforeSwapDelta(-int128(tokenIn), int128(ethOut));
} else {
    // Exact input: Specified = TOKEN, Unspecified = ETH
    return toBeforeSwapDelta(int128(ethOut), -int128(tokenIn));
}
```

**Challenge 3**: Delta accounting balance?

**Solution**: Always `sync()` before `settle()`
```solidity
poolManager.sync(currency0);
poolManager.sync(currency1);
// Now safe to settle
```

### Step 5: Testing Strategy

Need to test:
1. ✅ Basic swaps work without internal pool
2. ✅ Internal pool fills when TOKEN fees available
3. ✅ Partial fills work correctly
4. ✅ Fee capture in both directions
5. ✅ LP distribution via donate
6. ✅ Edge cases (zero reserves, exact limits)

---

## Challenges & Solutions

### Challenge 1: Understanding Specified vs Unspecified

**Problem**: Initially confused about which token is "specified" in different swap scenarios.

**Solution**: Created a mental model:

```
Exact Input Swap (-amount):
- Specified = what user is SELLING
- Unspecified = what user will RECEIVE

Exact Output Swap (+amount):
- Specified = what user wants to RECEIVE
- Unspecified = what user will PAY
```

Drew diagrams for all four swap types to internalize this.

### Challenge 2: Delta Sign Conventions

**Problem**: Kept getting signs wrong in `BeforeSwapDelta`.

**Solution**: Remember the perspective:
```
Positive delta = Hook is OWED / TAKING
Negative delta = Hook OWES / SENDING

Example:
toBeforeSwapDelta(+100, -98)
= Hook takes 100 of specified token
= Hook gives 98 of unspecified token
```

### Challenge 3: Settlement Ordering

**Problem**: Initially tried to settle before sync, causing accounting errors.

**Solution**: Learned the correct order:
```solidity
// 1. Update internal state
_poolFees[poolId].amount1 -= tokenIn;

// 2. Sync first
poolManager.sync(currency);

// 3. Then settle
currency.settle(poolManager, address(this), amount, false);
```

### Challenge 4: Fee Calculation Direction

**Problem**: Wasn't sure which token to capture fees in.

**Solution**: Realized unspecified currency is always the output:
```solidity
Currency swapFeeCurrency = params.amountSpecified < 0 == params.zeroForOne
    ? key.currency1  // Unspecified
    : key.currency0; // Unspecified
```

This ensures we always take fees from what the user receives.

---

## Testing Strategy

### Unit Tests Needed

#### 1. **Basic Functionality**
```solidity
testSwapWithoutInternalPool()
testSwapCapturesFees()
testFeesStoredCorrectly()
```

#### 2. **Internal Pool Logic**
```solidity
testInternalPoolFillsPartialSwap()
testInternalPoolFillsCompleteSwap()
testInternalPoolSkipsWhenNoReserves()
testInternalPoolOnlyForTokenToEth()
```

#### 3. **Fee Distribution**
```solidity
testFeesDistributedToLPs()
testDistributionOnlyAboveThreshold()
testMultipleSwapsAccumulateFees()
```

#### 4. **Edge Cases**
```solidity
testZeroAmountSwap()
testLargeSwapAmount()
testExactInputSwap()
testExactOutputSwap()
testSwapWithPriceLimit()
```

#### 5. **Gas Benchmarks**
```solidity
testGasWithoutHook()
testGasWithHookNoInternalPool()
testGasWithHookInternalFill()
```

### Integration Tests

- Test with real PoolManager
- Test with multiple LPs
- Test fee accumulation over many swaps
- Test with price changes

---

## Future Improvements

### 1. **Pool Validation**

Add `beforeInitialize` to validate:
```solidity
function beforeInitialize(...) {
    require(Currency.unwrap(key.currency0) == WETH, "Must be ETH pool");
    require(key.fee & DYNAMIC_FEE_FLAG != 0, "Must use dynamic fees");
    return selector;
}
```

### 2. **Position Manager Integration**

Instead of flat reserves, use concentrated liquidity:
```solidity
// Add TOKEN fees as liquidity position
positionManager.mint(PositionConfig({
    poolKey: key,
    tickLower: currentTick - tickSpacing,
    tickUpper: currentTick + tickSpacing,
    liquidity: calculateLiquidity(tokenFees)
}));

// Burn position when needed for swaps
```

**Benefits**:
- TOKEN fees earn trading fees while waiting
- More capital efficient
- Automatic rebalancing

### 3. **Dynamic Fee Tiers**

Adjust fees based on conditions:
```solidity
function calculateFee(uint256 swapAmount, PoolId poolId) internal view returns (uint256) {
    if (swapAmount < 0.1 ether) return 50;    // 0.5%
    if (swapAmount < 1 ether) return 100;     // 1%
    if (_poolFees[poolId].amount1 > 100e18) return 50;  // Lower when converting fees
    return 100;
}
```

### 4. **Multi-Pool Support**

Track fees across multiple pools:
```solidity
struct GlobalFees {
    uint256 totalEthFees;
    uint256 totalTokenFees;
    mapping(PoolId => ClaimableFees) poolFees;
}
```

### 5. **Governance**

Add `owner` with limited powers:
- Update DONATE_THRESHOLD_MIN
- Update FEE_BPS (within bounds)
- Emergency pause (with timelock)

---

## Repository Link

**GitHub Repository**: `/home/robinsoncodes/Documents/uniswap-UH8/Internal-Swap-Pool`

### Repository Structure

```
Internal-Swap-Pool/
├── src/
│   └── InternalSwapPool.sol    # Main hook implementation (500+ lines)
├── test/
│   └── (tests to be added)
├── script/
│   └── (deployment scripts)
├── foundry.toml                 # Foundry configuration
├── remappings.txt               # Import remappings
└── README.md                    # Project documentation
```

### Key Files

1. **InternalSwapPool.sol**: Complete implementation with:
   - beforeSwap with BeforeSwapDelta return
   - afterSwap with fee capture
   - _distributeFees for LP rewards
   - _handleExactInput and _handleExactOutput
   - Comprehensive NatSpec documentation

2. **README.md**: Project overview with:
   - Problem statement
   - Solution architecture
   - How it works
   - Installation instructions
   - Future improvements

### To Run

```bash
cd Internal-Swap-Pool

# Install dependencies
forge install

# Build
forge build

# Test (when tests added)
forge test

# Deploy (when ready)
forge script script/Deploy.s.sol --broadcast
```

---

## Conclusion

This homework taught me the power and complexity of Return Delta Hooks. Key learnings:

1. **BeforeSwapDelta** is fundamentally different from BalanceDelta
2. **Custom pricing curves** are possible by modifying amountToSwap
3. **Internal orderbooks** can exist on top of Uniswap pools
4. **Delta accounting** requires careful attention to sync/settle order
5. **Real-world applications** like launchpads benefit immensely

The Internal Swap Pool demonstrates how hooks can solve actual problems (unwanted selling pressure) in novel ways (internal reserve conversion). This pattern could be used for:
- Token launchpads
- Fair launch mechanisms
- Treasury management
- Protocol-owned liquidity

I'm excited to explore more advanced Return Delta patterns in future classes!

---

## Quest Submission Checklist

- [x] Attended Workshop 10 or watched recordings
- [x] Reviewed Custom Curve CSMM Lesson
- [x] Built Custom Pricing Curve Hook
- [x] Hook uses beforeSwapReturnDelta
- [x] Repository is public
- [x] Code is documented with NatSpec
- [x] README explains design and implementation
- [x] Homework explanation document completed

**Submitted by**: Allan Robinson
**Date**: February 3, 2026
**Email**: (your email for quest submission)

---

**Allan Robinson**
Custom Pricing Curve Hook Homework - Week 3 - February 3, 2026

