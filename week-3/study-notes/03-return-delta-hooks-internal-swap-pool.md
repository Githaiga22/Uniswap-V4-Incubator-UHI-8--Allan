# Week 3 Session 1: Return Delta Hooks & Internal Swap Pool

**Author**: Allan Robinson
**Date**: February 3, 2026 (Tuesday)
**Session**: Week 3, Day 1 - Atrium Academy Class 5

---

## Session Overview

Today marked our 5th class at Atrium Academy and we dove deep into **Return Delta Hooks** (also called **NoOp Hooks**). This is one of the most powerful features in Uniswap V4 that allows hooks to completely customize swap logic and even bypass the core AMM pricing curve.

We built an Internal Swap Pool hook that:
- Routes all fees to a single token (Currency0/ETH)
- Creates an internal orderbook to fill swaps before they hit Uniswap
- Distributes fees to LPs without selling pressure
- Perfect for token launchpads and fair launch mechanisms

---

## Lesson Objectives

By the end of today's session, I should be able to:

✅ Understand Return Delta hooks and why they're called "NoOp"
✅ Distinguish between `BalanceDelta` and `BeforeSwapDelta`
✅ Use `beforeSwapReturnDelta` to customize swap logic
✅ Implement an internal swap pool that frontruns Uniswap swaps
✅ Build custom pricing curves

---

## What Are NoOp Hooks?

### The Name Origin

**NoOp** = **No Operation**

This is a computer science term for machine instructions that tell the system to "do nothing".

In Uniswap V4 context:
- NoOp Hooks can ask the PoolManager to "skip" certain operations
- Specifically, they can bypass the core AMM swap logic
- The PoolManager still calls the hook - but the pool's swap logic doesn't execute

```
┌─────────────────────────────────────────┐
│        REGULAR SWAP (No Hook)           │
├─────────────────────────────────────────┤
│                                         │
│  User → Swap Router → PoolManager       │
│         → Core AMM Logic (x*y=k)        │
│         → Price Update                  │
│         → Balance Changes               │
│                                         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│      NOOP HOOK SWAP (Custom Logic)      │
├─────────────────────────────────────────┤
│                                         │
│  User → Swap Router → PoolManager       │
│         → beforeSwap (Hook)             │
│         → ❌ Core AMM Skipped (NoOp)    │
│         → ✅ Custom Pricing Logic       │
│         → Balance Changes               │
│                                         │
└─────────────────────────────────────────┘
```

**Key Insight**: The hook takes over swap execution instead of Uniswap's default x*y=k curve.

---

## Return Delta Hook Types

There are **four types** of Return Delta hook functions:

### 1. beforeSwapReturnDelta

**What it does**:
- Partially or completely bypass core swap logic
- Take over swap execution inside `beforeSwap`
- Implement custom pricing curves

**Use cases**:
- Custom AMM curves (constant sum, constant product variations)
- Internal orderbooks
- MEV protection with custom pricing
- Fair launch mechanisms

### 2. afterSwapReturnDelta

**What it does**:
- Extract tokens from swap output (take fees)
- Charge users additional tokens beyond input amount
- Add bonus tokens to swap output

**Use cases**:
- Custom fee collection
- Loyalty rewards (bonus tokens)
- Tiered pricing based on user status

### 3. afterAddLiquidityReturnDelta

**What it does**:
- Charge users extra when adding liquidity
- Give users bonus tokens when adding liquidity

**Use cases**:
- Liquidity mining incentives
- Deposit fees for specialized pools

### 4. afterRemoveLiquidityReturnDelta

**What it does**:
- Same as above but for removing liquidity

**Use cases**:
- Exit fees
- Early withdrawal penalties
- Liquidity commitment rewards

---

## BalanceDelta vs BeforeSwapDelta

This is **critical** to understand. They look similar but are fundamentally different.

### BalanceDelta Format

```solidity
BalanceDelta = (amount0, amount1)
```

- **Always** in the form (token0 delta, token1 delta)
- Returned from `swap()`, `modifyLiquidity()`, etc.
- Represents changes in token0 and token1 balances
- **Fixed order**: token0 first, token1 second

**Example**:
```solidity
BalanceDelta delta = swap(...);
// delta = (-100, +98)
// Means: User owes 100 of token0, receives 98 of token1
```

### BeforeSwapDelta Format

```solidity
BeforeSwapDelta = (amountSpecified, amountUnspecified)
```

- **Variable** format depending on swap direction
- Returned from `beforeSwap()` if `beforeSwapReturnDelta` enabled
- First value = delta of the "specified" token
- Second value = delta of the "unspecified" token

**What does "specified" mean?**

Recall the four swap configurations:

| Swap Type | zeroForOne | amountSpecified | Specified Token | Unspecified Token |
|-----------|------------|-----------------|-----------------|-------------------|
| Exact Input 0→1 | true | negative | token0 | token1 |
| Exact Output 0→1 | true | positive | token1 | token0 |
| Exact Input 1→0 | false | negative | token1 | token0 |
| Exact Output 1→0 | false | positive | token0 | token1 |

**Example 1**: Exact Input swap, selling 100 token0 for token1
```solidity
// User params
zeroForOne = true
amountSpecified = -100  // Negative = exact input

// Specified token = token0 (what user is selling)
// Unspecified token = token1 (what user receives)

BeforeSwapDelta = (amountSpecifiedDelta, amountUnspecifiedDelta)
                = (token0 delta, token1 delta)
```

**Example 2**: Exact Output swap, buying 100 token1 with token0
```solidity
// User params
zeroForOne = true
amountSpecified = +100  // Positive = exact output

// Specified token = token1 (what user wants to receive)
// Unspecified token = token0 (what user will pay)

BeforeSwapDelta = (amountSpecifiedDelta, amountUnspecifiedDelta)
                = (token1 delta, token0 delta)  // Order flipped!
```

### Why This Matters

The `BeforeSwapDelta` format allows hooks to:
1. "Consume" the user's input token
2. Provide the output token from hook's reserves
3. Modify `amountToSwap` for the core AMM

```
┌─────────────────────────────────────────┐
│     HOW BEFORESWAP DELTA WORKS          │
├─────────────────────────────────────────┤
│                                         │
│  User wants: Sell 100 A for B           │
│                                         │
│  1. amountToSwap = -100 A               │
│                                         │
│  2. beforeSwap returns:                 │
│     BeforeSwapDelta = (+50 A, -48 B)    │
│                                         │
│  3. Hook "consumed" 50 A delta:         │
│     amountToSwap = -100 + 50 = -50 A    │
│                                         │
│  4. Core AMM only swaps 50 A            │
│     (instead of 100 A)                  │
│                                         │
│  5. Hook provided 48 B from reserves    │
│     User gets: 48 B (hook) + X B (AMM)  │
│                                         │
└─────────────────────────────────────────┘
```

---

## How BeforeSwapDelta Modifies amountToSwap

Let's trace through the actual code to understand the mechanism.

### In PoolManager.sol

```solidity
function swap(PoolKey memory key, IPoolManager.SwapParams memory params, bytes calldata hookData)
    external
    returns (BalanceDelta swapDelta)
{
    BeforeSwapDelta beforeSwapDelta;
    {
        int256 amountToSwap;
        uint24 lpFeeOverride;

        // Call beforeSwap hook
        (amountToSwap, beforeSwapDelta, lpFeeOverride) = key.hooks.beforeSwap(key, params, hookData);

        // Core swap uses amountToSwap, NOT params.amountSpecified!
        swapDelta = _swap(
            pool,
            id,
            Pool.SwapParams({
                tickSpacing: key.tickSpacing,
                zeroForOne: params.zeroForOne,
                amountSpecified: amountToSwap,  // ← Modified by hook!
                sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                lpFeeOverride: lpFeeOverride
            }),
            params.zeroForOne ? key.currency0 : key.currency1
        );
    }
}
```

**Key observation**: The core `_swap()` function gets `amountToSwap`, not `params.amountSpecified`.

### In Hooks.sol

```solidity
function beforeSwap(IHooks self, PoolKey memory key, IPoolManager.SwapParams memory params, bytes calldata hookData)
    internal
    returns (int256 amountToSwap, BeforeSwapDelta hookReturn, uint24 lpFeeOverride)
{
    // Start with user's specified amount
    amountToSwap = params.amountSpecified;

    if (self.hasPermission(BEFORE_SWAP_FLAG)) {
        bytes memory result = callHook(self, abi.encodeCall(IHooks.beforeSwap, (msg.sender, key, params, hookData)));

        if (self.hasPermission(BEFORE_SWAP_RETURNS_DELTA_FLAG)) {
            hookReturn = BeforeSwapDelta.wrap(result.parseReturnDelta());

            // Extract the specified token delta from hook
            int128 hookDeltaSpecified = hookReturn.getSpecifiedDelta();

            // Modify amountToSwap based on hook's delta
            if (hookDeltaSpecified != 0) {
                bool exactInput = amountToSwap < 0;
                amountToSwap += hookDeltaSpecified;  // ← THE MAGIC!

                // Ensure swap direction doesn't flip
                if (exactInput ? amountToSwap > 0 : amountToSwap < 0) {
                    HookDeltaExceedsSwapAmount.selector.revertWith();
                }
            }
        }
    }
}
```

**The Magic Line**: `amountToSwap += hookDeltaSpecified`

### Example Walkthrough

**Scenario**: User wants to sell 100 token0 for token1 (exact input)

```solidity
// Initial state
params.amountSpecified = -100  // Sell 100 token0
amountToSwap = -100

// Hook returns
BeforeSwapDelta = (+60, -58)  // Hook consumed 60 token0, gave 58 token1

// Extraction
hookDeltaSpecified = +60  // Specified token is token0

// Modification
amountToSwap += hookDeltaSpecified
amountToSwap = -100 + 60 = -40

// Result
// Core AMM only swaps 40 token0 (instead of 100)
// Hook already handled 60 token0 → 58 token1
```

**If hook fully handles swap**:
```solidity
// Hook returns
BeforeSwapDelta = (+100, -98)  // Hook consumed ALL 100 token0

// Modification
amountToSwap = -100 + 100 = 0  // Zero!

// Result
// Core AMM skipped (NoOp) because amountToSwap = 0
// Hook handled entire swap: 100 token0 → 98 token1
```

---

## Simplified Flow: Regular vs NoOp Swap

### Regular Swap (No Return Delta)

```
┌─────────────────────────────────────────┐
│         REGULAR SWAP FLOW               │
├─────────────────────────────────────────┤
│                                         │
│  1. User: "Sell 1 ETH for TOKEN"        │
│     amountSpecified = -1 ETH            │
│                                         │
│  2. Swap Router → PoolManager           │
│                                         │
│  3. PoolManager → beforeSwap hook       │
│     (hook does bookkeeping only)        │
│                                         │
│  4. PoolManager → pools[id].swap        │
│     Uses x*y=k curve                    │
│     amountToSwap = -1 ETH               │
│                                         │
│  5. Pool calculates:                    │
│     User gets 100 TOKEN                 │
│     BalanceDelta = (-1 ETH, +100 TOKEN) │
│                                         │
│  6. PoolManager → afterSwap hook        │
│     (hook does more bookkeeping)        │
│                                         │
│  7. Swap Router settles balances        │
│     User sends 1 ETH → PM               │
│     User receives 100 TOKEN ← PM        │
│                                         │
│  ✅ Transaction complete                │
│                                         │
└─────────────────────────────────────────┘
```

### NoOp Swap (With beforeSwapReturnDelta)

```
┌─────────────────────────────────────────┐
│          NOOP SWAP FLOW                 │
├─────────────────────────────────────────┤
│                                         │
│  1. User: "Sell 1 ETH for TOKEN"        │
│     amountSpecified = -1 ETH            │
│                                         │
│  2. Swap Router → PoolManager           │
│                                         │
│  3. PoolManager → beforeSwap hook       │
│                                         │
│  4. Hook has 100 TOKEN in reserves      │
│     Hook decides to fill entire swap!   │
│                                         │
│  5. Hook returns:                       │
│     BeforeSwapDelta = (+1 ETH, -100 T)  │
│     Meaning:                            │
│     - Hook consumed user's 1 ETH        │
│     - Hook giving user 100 TOKEN        │
│                                         │
│  6. amountToSwap calculation:           │
│     amountToSwap = -1 + 1 = 0           │
│                                         │
│  7. PoolManager → pools[id].swap        │
│     amountToSwap = 0 ❌ SKIPPED!        │
│     Core AMM logic doesn't run          │
│                                         │
│  8. Final BalanceDelta:                 │
│     (-1 ETH, +100 TOKEN)                │
│                                         │
│  9. Swap Router settles balances        │
│     User sends 1 ETH → PM → Hook        │
│     User receives 100 TOKEN ← Hook      │
│                                         │
│  ✅ Transaction complete                │
│     (Pool reserves unchanged!)          │
│                                         │
└─────────────────────────────────────────┘
```

**Critical Difference**: The pool's reserves and price never changed! The hook acted as an internal orderbook.

---

## Internal Swap Pool: Problem Statement

### The Launchpad Problem

Imagine you're building a token launchpad. Users buy your TOKEN with ETH.

**Traditional Uniswap V3/V4 behavior**:

```
Token Pool: ETH/TOKEN

Swaps happening:
- ETH → TOKEN (users buying)    ← Common
- TOKEN → ETH (users selling)   ← Less common

Fees collected:
- When users buy (ETH → TOKEN):
  → Fees collected in TOKEN

- When users sell (TOKEN → ETH):
  → Fees collected in ETH

LPs earn fees in BOTH tokens!
```

**The problem**:

1. LPs accumulate TOKEN fees
2. To realize profit, LPs must sell TOKEN for ETH
3. Selling TOKEN creates **downward price pressure**
4. This hurts TOKEN holders
5. Creates misaligned incentives

**What if we could**:

```
✅ Collect ALL fees in ETH
✅ LPs never need to sell TOKEN
✅ Zero selling pressure on TOKEN
✅ Everyone wins
```

This is what our Internal Swap Pool solves!

---

## Internal Swap Pool: Design

### High-Level Mechanism

```
┌─────────────────────────────────────────┐
│      INTERNAL SWAP POOL DESIGN          │
├─────────────────────────────────────────┤
│                                         │
│  Hook maintains internal reserves:     │
│  - ETH: 0                               │
│  - TOKEN: 50 (collected from fees)      │
│                                         │
│  User wants: Sell TOKEN for ETH        │
│                                         │
│  beforeSwap:                            │
│  1. Check if TOKEN → ETH swap           │
│  2. Check if hook has TOKEN reserves    │
│  3. If yes: Fill from internal pool     │
│     - Hook takes user's TOKEN           │
│     - Hook gives user ETH               │
│     - Return BeforeSwapDelta to skip    │
│       core AMM (or partial fill)        │
│                                         │
│  Result:                                │
│  - User gets fair price                 │
│  - Uniswap pool unchanged               │
│  - Hook converts TOKEN fees → ETH fees  │
│                                         │
│  afterSwap:                             │
│  - Capture fees in afterSwapReturnDelta │
│  - Distribute ETH fees to LPs via donate│
│                                         │
└─────────────────────────────────────────┘
```

### Flow Diagram

```
USER BUYS TOKEN (ETH → TOKEN):
┌────────┐
│  User  │ "Buy TOKEN with 1 ETH"
└───┬────┘
    │
    ▼
┌────────────────┐
│  beforeSwap    │ No internal pool action
└───┬────────────┘
    │
    ▼
┌────────────────┐
│  Core Swap     │ Uniswap AMM executes
│  1 ETH → 100 T │
└───┬────────────┘
    │
    ▼
┌────────────────┐
│  afterSwap     │ Capture 1% fee = 1 TOKEN
│                │ Store internally
└───┬────────────┘
    │
    ▼
┌────────────────┐
│  Hook State    │
│  ETH: 0        │
│  TOKEN: 1      │
└────────────────┘

USER SELLS TOKEN (TOKEN → ETH):
┌────────┐
│  User  │ "Sell 50 TOKEN for ETH"
└───┬────┘
    │
    ▼
┌────────────────┐
│  beforeSwap    │ Hook has 1 TOKEN in reserve
│                │ Can partially fill swap!
│                │
│                │ Calculate:
│                │ - Take 1 TOKEN from user
│                │ - Give 0.01 ETH to user
│                │ - Return BeforeSwapDelta
│                │   (+1 TOKEN, -0.01 ETH)
└───┬────────────┘
    │
    ▼
┌────────────────┐
│  amountToSwap  │ Originally: -50 TOKEN
│  Modified      │ Now: -49 TOKEN
│                │ (49 TOKEN still needs AMM)
└───┬────────────┘
    │
    ▼
┌────────────────┐
│  Core Swap     │ Uniswap AMM swaps 49 TOKEN
│ 49 TOKEN → ETH │
└───┬────────────┘
    │
    ▼
┌────────────────┐
│  afterSwap     │ Capture 1% fee
│                │ Distribute ETH fees to LPs
└───┬────────────┘
    │
    ▼
┌────────────────┐
│  Hook State    │
│  ETH: +0.01    │ Internal TOKEN sold for ETH!
│  TOKEN: 0      │ (Ready to distribute to LPs)
└────────────────┘
```

**Key benefit**: TOKEN fees are converted to ETH **without hitting the Uniswap pool**, avoiding price impact!

---

## Implementation: InternalSwapPool Hook

Let's build this step by step. I'll break down the code into digestible pieces.

### Step 1: Contract Setup

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {SwapMath} from '@uniswap/v4-core/src/libraries/SwapMath.sol';
import {Hooks, IHooks} from '@uniswap/v4-core/src/libraries/Hooks.sol';
import {BalanceDelta} from '@uniswap/v4-core/src/types/BalanceDelta.sol';
import {Currency, CurrencyLibrary} from '@uniswap/v4-core/src/types/Currency.sol';
import {PoolId, PoolIdLibrary} from '@uniswap/v4-core/src/types/PoolId.sol';
import {PoolKey} from '@uniswap/v4-core/src/types/PoolKey.sol';
import {BeforeSwapDelta, toBeforeSwapDelta} from '@uniswap/v4-core/src/types/BeforeSwapDelta.sol';
import {StateLibrary} from '@uniswap/v4-core/src/libraries/StateLibrary.sol';
import {CurrencySettler} from '@uniswap/v4-core/test/utils/CurrencySettler.sol';

import {IPoolManager} from '@uniswap/v4-core/src/interfaces/IPoolManager.sol';
import {BaseHook} from 'v4-periphery/src/utils/BaseHook.sol';

contract InternalSwapPool is BaseHook {
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    /// Minimum threshold for donations (prevents gas waste)
    uint public constant DONATE_THRESHOLD_MIN = 0.0001 ether;

    /// Native token address (ETH or WETH)
    address public immutable nativeToken;

    /**
     * Internal fee tracking per pool
     */
    struct ClaimableFees {
        uint amount0;  // ETH fees
        uint amount1;  // TOKEN fees
    }

    /// Maps PoolId to claimable fees
    mapping(PoolId => ClaimableFees) internal _poolFees;

    constructor(address _poolManager, address _nativeToken)
        BaseHook(IPoolManager(_poolManager))
    {
        nativeToken = _nativeToken;
    }

    /**
     * Get current fees for a pool
     */
    function poolFees(PoolKey calldata _poolKey)
        public
        view
        returns (ClaimableFees memory)
    {
        return _poolFees[_poolKey.toId()];
    }
}
```

**What we've set up**:
- Track fees per pool (ETH and TOKEN separately)
- Store native token address
- Helper function to query fees

### Step 2: Hook Permissions

```solidity
function getHookPermissions()
    public
    pure
    override
    returns (Hooks.Permissions memory)
{
    return Hooks.Permissions({
        beforeInitialize: false,
        afterInitialize: false,
        beforeAddLiquidity: false,
        afterAddLiquidity: false,
        beforeRemoveLiquidity: false,
        afterRemoveLiquidity: false,
        beforeSwap: true,                    // ✅ Fill internal swaps
        afterSwap: true,                     // ✅ Capture fees
        beforeDonate: false,
        afterDonate: false,
        beforeSwapReturnDelta: true,         // ✅ Custom pricing
        afterSwapReturnDelta: true,          // ✅ Fee extraction
        afterAddLiquidityReturnDelta: false,
        afterRemoveLiquidityReturnDelta: false
    });
}
```

**Permissions we need**:
1. `beforeSwap` + `beforeSwapReturnDelta`: Fill swaps from internal pool
2. `afterSwap` + `afterSwapReturnDelta`: Capture fees and distribute

### Step 3: Fee Distribution (donate)

This function converts accumulated ETH fees into LP rewards via `donate()`.

```solidity
/**
 * Distributes accumulated ETH fees to LPs
 */
function _distributeFees(PoolKey calldata _poolKey) internal {
    PoolId poolId = _poolKey.toId();
    uint donateAmount = _poolFees[poolId].amount0;  // ETH fees

    // Only donate if above minimum threshold
    if (donateAmount < DONATE_THRESHOLD_MIN) {
        return;
    }

    // Donate to LPs (all in token0/ETH)
    BalanceDelta delta = poolManager.donate(_poolKey, donateAmount, 0, '');

    // Settle the donation (we owe ETH to PoolManager)
    if (delta.amount0() < 0) {
        _poolKey.currency0.settle(
            poolManager,
            address(this),
            uint(uint128(-delta.amount0())),
            false
        );
    }

    // Reduce our tracked fees
    _poolFees[poolId].amount0 -= donateAmount;
}
```

**What `donate()` does**:
- Sends tokens to currently active LPs
- LPs can claim these as rewards
- Only rewards LPs in-range (same as fee distribution)

**Why settle**:
- `donate()` creates a negative delta (we owe tokens)
- Must send tokens to PoolManager to balance accounting
- Use `CurrencySettler` library for this

---

## Step 4: Capturing Fees (afterSwap)

```solidity
function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4 selector_, int128 hookDeltaUnspecified_) {

    // Determine which token is the unspecified currency
    // (the one the user receives)
    Currency swapFeeCurrency = params.amountSpecified < 0 == params.zeroForOne
        ? key.currency1   // TOKEN
        : key.currency0;  // ETH

    // Get the unspecified amount (what user received)
    int128 swapAmount = params.amountSpecified < 0 == params.zeroForOne
        ? delta.amount1()
        : delta.amount0();

    // Calculate 1% fee
    uint swapFee = uint(uint128(swapAmount < 0 ? -swapAmount : swapAmount)) * 99 / 100;

    // Store fees internally
    _depositFees(
        key,
        params.zeroForOne ? swapFee : 0,      // amount0 (if selling TOKEN for ETH)
        !params.zeroForOne ? 0 : swapFee      // amount1 (if buying TOKEN with ETH)
    );

    // Take the fee from PoolManager to our contract
    swapFeeCurrency.take(poolManager, address(this), swapFee, false);

    // Reduce user's receive amount by the fee
    hookDeltaUnspecified_ = -int128(int(swapFee));

    // Distribute accumulated ETH fees to LPs
    _distributeFees(key);

    selector_ = IHooks.afterSwap.selector;
}

function _depositFees(
    PoolKey calldata _poolKey,
    uint _amount0,
    uint _amount1
) internal {
    PoolId poolId = _poolKey.toId();
    _poolFees[poolId].amount0 += _amount0;
    _poolFees[poolId].amount1 += _amount1;
}
```

**What's happening**:

1. **Identify unspecified currency**: The token user receives as output
2. **Calculate fee**: Take 1% of output amount
3. **Store internally**: Track in `_poolFees` mapping
4. **Extract from PoolManager**: Use `take()` to get tokens
5. **Reduce user output**: Return negative `hookDeltaUnspecified_`
6. **Distribute to LPs**: Call `_distributeFees()`

**The magic of afterSwapReturnDelta**:

```
Without afterSwapReturnDelta:
User swaps 1 ETH → Gets 100 TOKEN
Hook can't take anything

With afterSwapReturnDelta:
User swaps 1 ETH → Would get 100 TOKEN
Hook returns hookDeltaUnspecified_ = -1 TOKEN
User actually gets 99 TOKEN
Hook keeps 1 TOKEN as fee!
```

---

## Step 5: Internal Swap Pool (beforeSwap)

This is the most complex part. Let's break it down.

```solidity
function _beforeSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    bytes calldata hookData
) internal override returns (
    bytes4 selector_,
    BeforeSwapDelta beforeSwapDelta_,
    uint24 swapFee_
) {
    PoolId poolId = key.toId();

    // Only process if:
    // 1. Swapping TOKEN for ETH (zeroForOne = false)
    // 2. We have TOKEN fees to use
    if (!params.zeroForOne && _poolFees[poolId].amount1 != 0) {

        uint tokenIn;   // TOKEN we'll take from user
        uint ethOut;    // ETH we'll give to user

        // Get current pool price
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);

        // Handle based on exact input vs exact output
        if (params.amountSpecified >= 0) {
            // EXACT OUTPUT: User wants specific amount of ETH
            _handleExactOutput(
                poolId,
                key,
                params,
                sqrtPriceX96,
                tokenIn,
                ethOut
            );
        } else {
            // EXACT INPUT: User selling specific amount of TOKEN
            _handleExactInput(
                poolId,
                key,
                params,
                sqrtPriceX96,
                tokenIn,
                ethOut
            );
        }

        // Update internal fee reserves
        _poolFees[poolId].amount0 += ethOut;    // Gained ETH
        _poolFees[poolId].amount1 -= tokenIn;   // Spent TOKEN

        // Sync balances with PoolManager
        poolManager.sync(key.currency0);
        poolManager.sync(key.currency1);

        // Transfer tokens
        poolManager.take(key.currency0, address(this), ethOut);  // Give ETH
        key.currency1.settle(poolManager, address(this), tokenIn, false);  // Take TOKEN
    }

    selector_ = IHooks.beforeSwap.selector;
}
```

Now let's implement the two helper functions for exact input vs exact output.

### Exact Output Handling

```solidity
/**
 * User specified exact ETH output amount
 * We need to calculate TOKEN input
 */
function _handleExactOutput(
    PoolId poolId,
    PoolKey calldata key,
    SwapParams calldata params,
    uint160 sqrtPriceX96,
    out uint tokenIn,
    out uint ethOut
) internal view {
    // User wants X amount of ETH
    // We can provide min(X, available_token_fees_worth)

    uint amountSpecified = uint(params.amountSpecified) > _poolFees[poolId].amount1
        ? _poolFees[poolId].amount1
        : uint(params.amountSpecified);

    // Use SwapMath to calculate amounts at current price
    // No fee (feePips = 0) because we're helping the ecosystem
    (, ethOut, tokenIn,) = SwapMath.computeSwapStep({
        sqrtPriceCurrentX96: sqrtPriceX96,
        sqrtPriceTargetX96: params.sqrtPriceLimitX96,
        liquidity: poolManager.getLiquidity(poolId),
        amountRemaining: int(amountSpecified),
        feePips: 0  // No fee for internal swaps!
    });

    // Return BeforeSwapDelta
    // Specified = TOKEN (what user wants to buy)
    // Unspecified = ETH (what user will pay)
    beforeSwapDelta_ = toBeforeSwapDelta(
        -int128(int(tokenIn)),   // Hook takes TOKEN
        int128(int(ethOut))      // Hook gives ETH
    );
}
```

### Exact Input Handling

```solidity
/**
 * User specified exact TOKEN input amount
 * We need to calculate ETH output
 */
function _handleExactInput(
    PoolId poolId,
    PoolKey calldata key,
    SwapParams calldata params,
    uint160 sqrtPriceX96,
    out uint tokenIn,
    out uint ethOut
) internal view {
    // User is selling X TOKEN
    // Calculate how much ETH all our TOKEN fees are worth

    (, ethOut, tokenIn,) = SwapMath.computeSwapStep({
        sqrtPriceCurrentX96: sqrtPriceX96,
        sqrtPriceTargetX96: params.sqrtPriceLimitX96,
        liquidity: poolManager.getLiquidity(poolId),
        amountRemaining: int(_poolFees[poolId].amount1),  // All TOKEN fees
        feePips: 0
    });

    // Check if user's input is enough to use all our fees
    if (ethOut > uint(-params.amountSpecified)) {
        // User input < our available fees
        // Scale down proportionally

        uint percentage = (uint(-params.amountSpecified) * 1e18) / ethOut;
        tokenIn = (tokenIn * percentage) / 1e18;
    }

    // Return BeforeSwapDelta
    // Specified = ETH (what user is spending)
    // Unspecified = TOKEN (what user will receive)
    beforeSwapDelta_ = toBeforeSwapDelta(
        int128(int(ethOut)),      // Hook gives ETH
        -int128(int(tokenIn))     // Hook takes TOKEN
    );
}
```

**Key insights**:

1. **Use SwapMath**: Calculate fair prices at current pool state
2. **No fees**: Internal swaps don't charge fees (benefits everyone)
3. **Proportional filling**: Only fill what we can with available reserves
4. **Price consistency**: Use pool's current price (no arbitrage)

---

## Complete Flow Example

Let's trace a complete user journey through the hook.

### Scenario Setup

```
Pool: ETH/TOKEN
Hook internal state:
- ETH: 0
- TOKEN: 0

LP adds liquidity: 10 ETH, 1000 TOKEN
Pool price: 1 ETH = 100 TOKEN
```

### Transaction 1: User Buys TOKEN

```
User: "Buy TOKEN with 1 ETH"

beforeSwap:
- No TOKEN fees available
- Skip (do nothing)
- Return BeforeSwapDelta = (0, 0)

Core Swap:
- Uniswap AMM executes normally
- 1 ETH → 99 TOKEN (with 0.3% Uniswap fee)

afterSwap:
- Output is TOKEN (unspecified currency)
- Calculate 1% fee: 99 * 0.01 = 0.99 TOKEN
- Store: _poolFees[poolId].amount1 += 0.99 TOKEN
- User receives: 99 - 0.99 = 98.01 TOKEN
- Distribute fees: Nothing to distribute (no ETH fees)

Hook state:
- ETH: 0
- TOKEN: 0.99

User final:
- Spent: 1 ETH
- Received: 98.01 TOKEN
```

### Transaction 2: User Sells TOKEN

```
User: "Sell 50 TOKEN for ETH"

beforeSwap:
- Swap direction: TOKEN → ETH (zeroForOne = false) ✅
- Hook has TOKEN fees: 0.99 TOKEN ✅
- Can partially fill!

Calculate using SwapMath:
- Current pool price: 1 ETH = 100 TOKEN
- Hook can sell: 0.99 TOKEN
- Hook will receive: ~0.0099 ETH

Return BeforeSwapDelta:
- Specified: ETH (exact input swap)
- BeforeSwapDelta = (+0.0099 ETH, -0.99 TOKEN)

amountToSwap modification:
- Original: -50 TOKEN
- Hook consumed: 0.99 TOKEN
- Remaining: -50 + 0.99 = -49.01 TOKEN

Core Swap:
- Uniswap AMM swaps 49.01 TOKEN → 0.4901 ETH

afterSwap:
- Output is ETH (unspecified currency)
- Calculate 1% fee: 0.4901 * 0.01 = 0.004901 ETH
- Store: _poolFees[poolId].amount0 += 0.004901 ETH
- User receives: 0.4901 - 0.004901 = 0.485199 ETH
- Distribute fees: 0.004901 ETH (below threshold, stored)

Hook state:
- ETH: 0.004901 + 0.0099 = 0.014801 ETH
- TOKEN: 0

User final:
- Spent: 50 TOKEN
- Received: 0.485199 + 0.0099 = 0.495099 ETH
```

**What happened**:
1. Hook converted TOKEN fees to ETH fees
2. User got fair market price
3. Uniswap pool less affected (49.01 TOKEN sold instead of 50)
4. LPs will receive ETH fees (not TOKEN!)

---

## Key Benefits of This Design

### 1. Single-Token Fee Distribution

```
❌ Traditional Uniswap:
LP receives fees in both ETH and TOKEN
Must sell TOKEN to realize profit
Selling creates downward pressure

✅ Internal Swap Pool:
LP receives fees ONLY in ETH
No need to sell TOKEN
Zero selling pressure
```

### 2. Reduced Price Impact

```
Without Hook:
User sells 50 TOKEN → Hits Uniswap pool fully
Price impact: 5%

With Hook:
Hook fills 0.99 TOKEN at fair price
Uniswap only sees 49.01 TOKEN
Price impact: 4.9%

Benefit: Slightly less slippage
```

### 3. Gas Efficiency

```
Internal fills use current pool price
No actual AMM swap computation needed
Cheaper gas for partial fills
```

### 4. Fair Launch Friendly

```
Token launchpads can use this to:
- Keep all LP rewards in ETH
- Minimize TOKEN sell pressure
- Align LP incentives with holders
- Support "up only" tokenomics
```

---

## Class Questions & Answers

### Q1: Do we specify static/dynamic fees when creating a pool?

**Answer**: Yes, in V4 you must set the `isDynamicFee` flag during pool initialization.

```solidity
// Static fee pool
PoolKey memory key = PoolKey({
    currency0: currency0,
    currency1: currency1,
    fee: 3000,  // 0.3% fixed
    tickSpacing: 60,
    hooks: IHooks(address(0))
});

// Dynamic fee pool
PoolKey memory key = PoolKey({
    currency0: currency0,
    currency1: currency1,
    fee: FeeLibrary.DYNAMIC_FEE_FLAG,  // Dynamic!
    tickSpacing: 60,
    hooks: IHooks(hookAddress)
});
```

### Q2: Can I override fee in beforeSwap if isDynamicFee is false?

**Answer**: No! The pool MUST be deployed with dynamic fees enabled. You cannot change fees on static-fee pools.

```solidity
function beforeSwap(...) external returns (bytes4, BeforeSwapDelta, uint24) {
    // This will revert if pool doesn't have dynamic fees
    return (
        IHooks.beforeSwap.selector,
        BeforeSwapDeltaLibrary.ZERO_DELTA,
        5000  // Try to set 0.5% fee - REVERTS on static fee pool!
    );
}
```

### Q3: Do beforeSwap and afterSwap execute in one block?

**Answer**: Yes! Both hooks execute within the same transaction/block. The flow is:

```
Single transaction:
1. beforeSwap executes
2. Core swap executes (maybe)
3. afterSwap executes
4. Balances settle
5. Transaction completes

All atomic - either all succeeds or all reverts
```

### Q4: What problem does this hook solve that cannot be solved off-chain?

**Answer**: The key is **atomicity** and **trustlessness**.

Off-chain, you'd need:
1. Monitor for TOKEN fees accumulating
2. Manually execute swaps to convert TOKEN → ETH
3. Manually distribute ETH to LPs
4. Hope you don't get front-run
5. Gas costs for separate transactions

With hooks:
- All happens automatically in swap transactions
- Zero trust required
- Atomic execution (no front-running risk)
- No separate gas costs
- LPs automatically receive correct token

### Q5: Dynamic fees - changing per swap vs rerouting fees?

**My question during class**: Can you explain the difference between:
1. Dynamic fees (changing fee % per swap based on data)
2. Dynamic fees (rerouting fees to entities other than LPs)

**Answer**: These are two separate concepts!

**Type 1: Variable Fee Percentage**
```solidity
function beforeSwap(...) returns (bytes4, BeforeSwapDelta, uint24 fee) {
    // Change fee based on volatility
    uint24 dynamicFee = volatilityHigh ? 10000 : 3000;  // 1% vs 0.3%
    return (selector, delta, dynamicFee);
}
```

**Type 2: Fee Routing/Distribution**
```solidity
function afterSwap(...) returns (bytes4, int128 hookDelta) {
    // Extract fees for non-LPs (protocol, token launcher, etc.)
    uint protocolFee = calculateFee(delta);

    // This goes to protocol, NOT to LPs
    currency.take(poolManager, protocolAddress, protocolFee);

    return (selector, -int128(protocolFee));
}
```

**Both can be "dynamic"** but serve different purposes:
- Type 1 affects how much users pay
- Type 2 affects who receives the fees

### Q6: How does Uniswap ensure hooks don't escape protocol fees?

**Answer**: Protocol fees are calculated and extracted **inside PoolManager**, before hooks run.

```solidity
// Inside PoolManager._swap()
function _swap(...) internal returns (BalanceDelta swapDelta) {
    // 1. Execute swap
    swapDelta = pool.swap(...);

    // 2. Calculate protocol fees (BEFORE hooks can interfere)
    uint protocolFee = calculateProtocolFee(swapDelta);

    // 3. Extract protocol fees to protocol address
    _accountProtocolFees(pool, protocolFee);

    // 4. NOW call afterSwap hook
    // Hook only sees remaining amounts after protocol fees taken
}
```

Hooks cannot bypass this because protocol fees are subtracted at the core level.

### Q7: Why afterSwap vs beforeSwap for custom fee distribution?

**My question**: If I want to give fees to entities other than LPs, why use afterSwap instead of beforeSwap?

**Answer**: Because of **delta accounting**!

```
beforeSwap:
- Swap hasn't happened yet
- Don't know final amounts
- Can't extract fees from non-existent outputs

afterSwap:
- Swap completed
- Know exact input/output amounts
- Can extract from output delta
- Use afterSwapReturnDelta to take fees
```

**Example**:
```solidity
// ❌ WRONG: Can't take fees in beforeSwap
function beforeSwap(...) returns (bytes4, BeforeSwapDelta, uint24) {
    // Swap hasn't happened - nothing to take!
    uint fee = ???  // Don't know output amount yet
}

// ✅ RIGHT: Take fees in afterSwap
function afterSwap(...) returns (bytes4, int128) {
    // Swap complete - we know user received X tokens
    int128 outputAmount = delta.amount1();
    uint fee = uint128(outputAmount) / 100;  // 1% of output

    // Extract fee from user's output
    currency.take(poolManager, feeRecipient, fee);

    return (selector, -int128(fee));  // Reduce user's amount
}
```

---

## Further Improvements

The current implementation is a basic version. Here are ideas to enhance it:

### 1. Pool Validation

```solidity
function beforeInitialize(
    address sender,
    PoolKey calldata key,
    uint160 sqrtPriceX96
) external override returns (bytes4) {
    // Validate currency0 is ETH
    require(
        Currency.unwrap(key.currency0) == nativeToken,
        "Currency0 must be ETH"
    );

    // Validate dynamic fees enabled
    require(
        key.fee & FeeLibrary.DYNAMIC_FEE_FLAG != 0,
        "Pool must use dynamic fees"
    );

    return IHooks.beforeInitialize.selector;
}
```

### 2: Position Manager Integration

Instead of maintaining internal TOKEN reserves, could use Uniswap's Position Manager:

```solidity
// In afterSwap: Add TOKEN fees as liquidity
function afterSwap(...) {
    if (tokenFeesAccumulated > threshold) {
        // Add TOKEN fees as liquidity to pool
        // This concentrates liquidity around current price
        positionManager.mint(...);
    }
}

// In beforeSwap: Burn liquidity to get TOKEN
function beforeSwap(...) {
    if (needTokenForSwap) {
        // Burn some position to get TOKEN
        positionManager.burn(...);
        // Use TOKEN to fill swap
    }
}
```

**Benefits**:
- TOKEN fees earn trading fees while waiting
- More capital efficient
- Natural price discovery

### 3. Multi-Tier Fee Structure

```solidity
// Charge different fees based on swap size
function calculateFee(uint swapAmount) internal pure returns (uint24) {
    if (swapAmount < 0.1 ether) return 500;   // 0.05%
    if (swapAmount < 1 ether) return 1000;    // 0.1%
    if (swapAmount < 10 ether) return 2000;   // 0.2%
    return 3000;  // 0.3% for large swaps
}
```

### 4. Whitelist for Fee Exemptions

```solidity
mapping(address => bool) public feeExempt;

function afterSwap(address sender, ...) {
    if (feeExempt[sender]) {
        // No fee for whitelisted addresses
        return (selector, 0);
    }

    // Normal fee logic
}
```

---

## Key Takeaways

### 1. BeforeSwapDelta is Powerful

- Can completely bypass Uniswap's AMM
- Enables custom pricing curves
- Perfect for internal orderbooks
- Must be used responsibly (fair pricing!)

### 2. Return Delta Hooks Are Complex

- Four types, each with different use cases
- Requires understanding delta accounting
- Must handle specified vs unspecified tokens correctly
- Testing is critical

### 3. Internal Swap Pools Solve Real Problems

- Single-token fee distribution
- Reduced price impact
- Better for token launches
- Aligned incentives

### 4. Always Use afterSwapReturnDelta for Fee Extraction

- beforeSwap: Don't know final amounts yet
- afterSwap: Know exact amounts, can extract fees
- Use negative hookDelta to reduce user output

### 5. This Is Just the Beginning

- Many more use cases for Return Delta hooks
- TWAMM (Time-Weighted AMM)
- Gradual Dutch Auctions
- Bonding curves
- Limit orders

---

## Homework: Custom Pricing Curve Hook

### Requirements

Build a custom pricing curve hook with:

1. ✅ Use beforeSwapReturnDelta
2. ✅ Implement custom pricing logic (not x*y=k)
3. ✅ Handle both swap directions
4. ✅ Public GitHub repository
5. ✅ Tests with >80% coverage
6. ✅ Documentation explaining your curve

### My Plan

I'll build a **Constant Sum Market Maker (CSMM)** hook:
- Linear pricing: x + y = k
- Perfect for stablecoin pairs
- Zero slippage up to reserves
- Simple to understand and test

**Next steps**:
1. Set up project structure
2. Implement CSMM logic
3. Write comprehensive tests
4. Document the mathematics
5. Submit to Atrium Academy

---

## Action Items

- [ ] Complete homework (CSMM hook)
- [ ] Test both exact input and exact output swaps
- [ ] Handle edge cases (zero reserves, max amounts)
- [ ] Write deployment scripts
- [ ] Submit GitHub link to quest

---

## Resources & References

### Code Examples
- [Internal Swap Pool (Haardik's repo)](https://github.com/haardikk21/csmm-noop-hook/tree/main)
- [Gas Price Hook (Dynamic Fees)](https://github.com/haardikk21/gas-price-hook)
- [Clanker Dynamic Fee Hook](https://github.com/clanker-devco/v4-contracts/blob/main/src/hooks/ClankerHookDynamicFeeV2.sol)
- [Flaunch Position Manager](https://github.com/flayerlabs/flaunchgg-contracts/blob/main/src/contracts/PositionManager.sol)

### Uniswap Documentation
- [Uniswap V4 Hooks](https://docs.uniswap.org/contracts/v4/concepts/hooks)
- [BeforeSwapDelta](https://docs.uniswap.org/contracts/v4/concepts/hooks#beforeswap-delta)

### Class Recording
- Workshop 10: Custom Curve CSMM Lesson

---

## Personal Reflections

Today's class was mind-bending. The power of Return Delta hooks is incredible - being able to completely bypass Uniswap's AMM and implement custom pricing curves opens up endless possibilities.

The Internal Swap Pool design is elegant. It solves a real problem (unwanted selling pressure from fee distributions) in a trustless, atomic way. This could be huge for token launchpads.

I'm excited to build my CSMM hook for homework. Understanding the math behind constant sum curves and implementing it with BeforeSwapDelta will solidify these concepts.

**Key insight from today**: Hooks aren't just about adding features on top of Uniswap - they can fundamentally change how the AMM works. We're building a new financial primitive here.

Next class: More advanced Return Delta patterns? Looking forward to it!

---

**Allan Robinson**
Return Delta Hooks & Internal Swap Pool - Week 3 Session 1 - February 3, 2026

