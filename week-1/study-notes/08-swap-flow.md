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
