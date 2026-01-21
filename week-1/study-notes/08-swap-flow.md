# Swap Flow - Complete Transaction Walkthrough

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## 🎓 What is a Swap Flow?

**One-line**: The step-by-step process of what happens when you trade one token for another in Uniswap V4.

**Simple Explanation**:
Think of ordering food delivery:
1. You open the app (connect to periphery)
2. Place your order (initiate swap)
3. Restaurant gets notification (beforeSwap hook)
4. Restaurant cooks food (actual swap logic)
5. Restaurant updates inventory (afterSwap hook)
6. Delivery driver brings food (settle balances)
7. You receive food (transaction complete!)

Each step has to happen in order, just like a V4 swap!

---

## 🎨 Visual: The Big Picture

```
┌──────────┐         ┌─────────────┐         ┌──────────────┐
│   USER   │────────→│ SWAP ROUTER │────────→│ POOL MANAGER │
│          │         │ (Periphery) │         │ (Singleton)  │
└──────────┘         └─────────────┘         └───────┬──────┘
                                                     │
                                                     │ (May call)
                                                     ↓
                                             ┌───────────────┐
                                             │ HOOK CONTRACT │
                                             │ (If enabled)  │
                                             └───────────────┘

FLOW:
User → Periphery → PoolManager → Hook → Back to PoolManager
                                       → Back to Periphery
                                       → Back to User
```

---

## 📝 Complete Swap Flow (No Hooks)

Let's start simple - a swap WITHOUT hooks:

```
SWAP: 1 ETH → ??? USDC
═══════════════════════

Step 1: User calls SwapRouter
┌─────────────────────────────────┐
│ swapRouter.swap({               │
│   tokenIn: ETH,                 │
│   tokenOut: USDC,               │
│   amountIn: 1 ETH               │
│ })                              │
└─────────────────────────────────┘
         │
         ↓

Step 2: SwapRouter unlocks PoolManager
┌─────────────────────────────────┐
│ poolManager.unlock(data)        │
│                                 │
│ • PoolManager unlocks           │
│ • Calls unlockCallback()        │
└─────────────────────────────────┘
         │
         ↓

Step 3: Inside unlockCallback
┌─────────────────────────────────┐
│ poolManager.swap(params)        │
│                                 │
│ • Validates pool exists         │
│ • Validates pool is initialized │
└─────────────────────────────────┘
         │
         ↓

Step 4: Execute swap math
┌─────────────────────────────────┐
│ • Calculate price impact        │
│ • Update pool reserves          │
│ • Calculate output amount       │
│ • Result: 1000 USDC             │
└─────────────────────────────────┘
         │
         ↓

Step 5: Charge protocol fees (if any)
┌─────────────────────────────────┐
│ • Take 0.01% for protocol       │
│ • Emit Swap event               │
└─────────────────────────────────┘
         │
         ↓

Step 6: Return BalanceDelta
┌─────────────────────────────────┐
│ BalanceDelta:                   │
│ • ETH:  -1 (user owes)          │
│ • USDC: +1000 (user receives)   │
└─────────────────────────────────┘
         │
         ↓

Step 7: Settle balances
┌─────────────────────────────────┐
│ SwapRouter:                     │
│ • Transfers 1 ETH to PM         │
│ • Receives 1000 USDC from PM    │
│ • Sends 1000 USDC to user       │
└─────────────────────────────────┘
         │
         ↓

Step 8: Callback returns, lock again
┌─────────────────────────────────┐
│ • Check deltas are zero ✅      │
│ • Lock PoolManager              │
│ • Transaction complete! 🎉      │
└─────────────────────────────────┘
```

---

## 📝 Complete Swap Flow (WITH Hooks)

Now with a hook that implements beforeSwap and afterSwap:

```
SWAP: 1 ETH → ??? USDC (with hook)
═══════════════════════════════════

Steps 1-3: Same as above
         │
         ↓

Step 4: Check if beforeSwap exists
┌─────────────────────────────────┐
│ • Read hook address bits        │
│ • Bit 8 set? YES ✓              │
│ • Must call beforeSwap          │
└─────────────────────────────────┘
         │
         ↓

Step 5: Call beforeSwap hook
┌─────────────────────────────────┐
│ hook.beforeSwap(params)         │
│                                 │
│ Hook logic:                     │
│ • Check if price is reasonable  │
│ • Verify user not blacklisted   │
│ • Custom validation             │
│ • Returns: OK to proceed ✅     │
└─────────────────────────────────┘
         │
         ↓

Step 6: Execute swap math (same as before)
┌─────────────────────────────────┐
│ • Calculate output: 1000 USDC   │
│ • Update pool state             │
└─────────────────────────────────┘
         │
         ↓

Step 7: Charge fees & emit event (same)
         │
         ↓

Step 8: Check if afterSwap exists
┌─────────────────────────────────┐
│ • Read hook address bits        │
│ • Bit 7 set? YES ✓              │
│ • Must call afterSwap           │
└─────────────────────────────────┘
         │
         ↓

Step 9: Call afterSwap hook
┌─────────────────────────────────┐
│ hook.afterSwap(params)          │
│                                 │
│ Hook logic:                     │
│ • Update TWAP oracle            │
│ • Give user loyalty points      │
│ • Log analytics                 │
│ • Returns: Success ✅           │
└─────────────────────────────────┘
         │
         ↓

Steps 10-11: Return delta, settle, lock (same as before)
```

---

## 🎨 Visual: Sequence Diagram

```
USER    ROUTER      POOL MGR       HOOK
 │        │            │            │
 │ Swap   │            │            │
 ├───────→│            │            │
 │        │ unlock()   │            │
 │        ├───────────→│            │
 │        │ callback   │            │
 │        │←───────────┤            │
 │        │            │            │
 │        │ swap()     │            │
 │        ├───────────→│            │
 │        │            │ before     │
 │        │            ├───────────→│
 │        │            │ OK         │
 │        │            │←───────────┤
 │        │            │            │
 │        │      [Execute swap]     │
 │        │            │            │
 │        │            │ after      │
 │        │            ├───────────→│
 │        │            │ OK         │
 │        │            │←───────────┤
 │        │            │            │
 │        │ delta      │            │
 │        │←───────────┤            │
 │        │            │            │
 │     [Settle balances]            │
 │        │            │            │
 │        │ lock ✅    │            │
 │        ├───────────→│            │
 │ USDC   │            │            │
 │←───────┤            │            │
 │        │            │            │
```

---

## 🔄 Multi-Hop Swap Flow

Most interesting case - swapping through multiple pools:

**Route**: ETH → USDC → DAI

```
Step 1-2: Unlock & callback (same as before)
         │
         ↓

Step 3: First swap (ETH → USDC)
┌─────────────────────────────────┐
│ swap(ETH/USDC pool)             │
│ • beforeSwap (if exists)        │
│ • Execute: 1 ETH → 1000 USDC    │
│ • afterSwap (if exists)         │
│                                 │
│ Delta: ETH: -1, USDC: +1000     │
└─────────────────────────────────┘
         │
         ↓

Step 4: Second swap (USDC → DAI)
┌─────────────────────────────────┐
│ swap(USDC/DAI pool)             │
│ • beforeSwap (if exists)        │
│ • Execute: 1000 USDC → 1000 DAI │
│ • afterSwap (if exists)         │
│                                 │
│ Delta: USDC: -1000, DAI: +1000  │
└─────────────────────────────────┘
         │
         ↓

Step 5: Net balances
┌─────────────────────────────────┐
│ Combined deltas:                │
│ • ETH:  -1    (user owes)       │
│ • USDC:  0    (cancelled out!)  │
│ • DAI:  +1000 (user receives)   │
│                                 │
│ Only 2 tokens need settlement!  │
└─────────────────────────────────┘
         │
         ↓

Step 6: Settle & lock
┌─────────────────────────────────┐
│ • Transfer 1 ETH to PM          │
│ • Transfer 1000 DAI to user     │
│ • NO USDC transfer needed! 🎉   │
│ • Lock PM                       │
└─────────────────────────────────┘
```

**Gas savings**: USDC never actually moved! Flash accounting FTW!

---

## 🎨 Visual: Balance Delta Tracking

```
MULTI-HOP SWAP: ETH → USDC → DAI
═══════════════════════════════

Initial State:
┌──────────────────────┐
│ Delta Tracker:       │
│ ETH:  0              │
│ USDC: 0              │
│ DAI:  0              │
└──────────────────────┘

After Swap 1 (ETH → USDC):
┌──────────────────────┐
│ Delta Tracker:       │
│ ETH:  -1   ❌        │
│ USDC: +1000 ✅       │
│ DAI:  0              │
└──────────────────────┘

After Swap 2 (USDC → DAI):
┌──────────────────────┐
│ Delta Tracker:       │
│ ETH:  -1   ❌        │
│ USDC: 0    ✅        │ ← Zeroed out!
│ DAI:  +1000 ✅       │
└──────────────────────┘

Settlement:
• Transfer 1 ETH  → PoolManager
• Transfer 1000 DAI → User
• USDC delta is 0, no transfer needed!

Final State:
┌──────────────────────┐
│ Delta Tracker:       │
│ ETH:  0    ✅        │
│ USDC: 0    ✅        │
│ DAI:  0    ✅        │
└──────────────────────┘
All balanced! Transaction succeeds!
```

---

## ⚠️ What Happens If Things Go Wrong?

### Scenario 1: Hook Rejects Swap
```
Step 1-4: Normal flow
         ↓
Step 5: beforeSwap hook
┌─────────────────────────────────┐
│ hook.beforeSwap()               │
│ • Checks price deviation        │
│ • Deviation > 5%                │
│ • revert("Price manipulation!") │
└─────────────────────────────────┘
         ↓
ENTIRE TRANSACTION REVERTS ❌
User gets error, swap cancelled
```

### Scenario 2: Unsettled Balances
```
Steps 1-9: Normal flow
         ↓
Step 10: Check if balanced
┌─────────────────────────────────┐
│ Delta Tracker:                  │
│ ETH:  -1   (user should pay)    │
│ USDC: +1000 (user should get)   │
└─────────────────────────────────┘
         ↓
Step 11: Try to settle
┌─────────────────────────────────┐
│ • User transfers 0.5 ETH (OOPS!)│
│ • Delta ETH: -0.5 (not zero!)   │
└─────────────────────────────────┘
         ↓
Step 12: Lock attempt
┌─────────────────────────────────┐
│ if (NonZeroDeltaCount != 0) {   │
│   revert("Not settled!");       │
│ }                               │
└─────────────────────────────────┘
         ↓
ENTIRE TRANSACTION REVERTS ❌
```

---

## 💡 Important Concepts

### 1. Atomicity
```
ALL steps happen in ONE transaction
Either EVERYTHING succeeds or NOTHING does
No partial swaps!

✅ Good: Swap completes, you get tokens
❌ Fail: Swap fails, you keep original tokens
🚫 NEVER: You lose tokens but don't get new ones
```

### 2. Slippage Protection
```
User sets: "I want at least 990 USDC"
Actual output: 985 USDC

985 < 990 → REVERT
Protects from price movements during transaction
```

### 3. Reentrancy Protection
```
Lock prevents:
User → unlock() → swap() → hook tries unlock() again
                                    ↑
                              REVERTS HERE!

Can't unlock twice in same transaction
```

---

## 🔗 Resources & Citations

1. **Atrium Academy - Swap Flow**
   https://learn.atrium.academy/course/4b6c25df-f4c8-4b92-ab38-a930284d237e/technical-introduction/v4-hooks

2. **Uniswap V4 PoolManager - Swap Function**
   https://github.com/Uniswap/v4-core/blob/main/src/PoolManager.sol

3. **Understanding Balance Deltas**
   https://docs.uniswap.org/contracts/v4/concepts/flash-accounting

---

## ✅ Quick Self-Check

1. **What's the first thing that happens when you swap?**
   <details>
   <summary>Answer</summary>
   The periphery contract (SwapRouter) calls unlock() on the PoolManager.
   </details>

2. **When does beforeSwap hook run?**
   <details>
   <summary>Answer</summary>
   After the swap is validated but BEFORE the actual swap math is executed.
   </details>

3. **What is BalanceDelta?**
   <details>
   <summary>Answer</summary>
   A record of how much each token balance has changed from the user's perspective. Negative = user owes, Positive = user receives.
   </details>

4. **Why are multi-hop swaps cheaper in V4?**
   <details>
   <summary>Answer</summary>
   Because intermediate tokens (like USDC in ETH→USDC→DAI) don't actually get transferred - their deltas cancel out.
   </details>

5. **What happens if balances aren't settled at the end?**
   <details>
   <summary>Answer</summary>
   The entire transaction reverts with a "CurrencyNotSettled" error.
   </details>

---

**Previous**: [Hook Mechanics](./07-hook-mechanics.md)
**Next**: [Liquidity Position Modification Flow](./09-liquidity-flow.md)
