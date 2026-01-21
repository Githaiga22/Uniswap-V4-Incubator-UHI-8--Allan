# Flash Accounting & Locking - The Smart Bookkeeping System

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## 🎓 What is Flash Accounting?

**One-line**: Flash Accounting tracks who owes what during a transaction, but only actually moves tokens at the very end.

**Simple Explanation**:
Imagine you're at a restaurant with friends, and you're splitting the bill:

**Old way (V3)**:
- You pay for appetizers → waiter takes your card
- Friend pays for main course → waiter takes their card
- Another friend pays for dessert → waiter takes their card
- Each transaction = separate charge

**New way (V4 - Flash Accounting)**:
- Keep a running tab on paper
- "You owe $20, Friend A owes $15, Friend B owes $25"
- At the END, calculate who owes what
- Make ONE final payment that settles everything

**Result**: Fewer transactions = lower fees = more money in your pocket!

---

## 🌍 Real-World Analogy: The Grocery Store

### V3: Old-Fashioned Store (Pay as You Go)
```
Customer Journey:

Step 1: Pick up milk
        ↓
     Pay for milk 💳 (transaction fee)

Step 2: Pick up bread
        ↓
     Pay for bread 💳 (transaction fee)

Step 3: Pick up eggs
        ↓
     Pay for eggs 💳 (transaction fee)

Total fees: 3× transaction fees
Time wasted: Lots!
```

### V4: Modern Store with Shopping Cart (Flash Accounting)
```
Customer Journey:

Step 1: Put milk in cart 🛒 (write it down)
Step 2: Put bread in cart 🛒 (write it down)
Step 3: Put eggs in cart 🛒 (write it down)
        ↓
     Checkout: Pay ONCE 💳 (one transaction fee)

Total fees: 1× transaction fee
Time saved: Tons!
```

---

## 🎨 Visual: V3 vs V4 Token Flow

### V3: Multi-Hop Swap (ETH → USDC → DAI)
```
┌──────┐                                           ┌──────┐
│ USER │                                           │ USER │
└───┬──┘                                           └───▲──┘
    │ 1. Send ETH                                      │
    v                                                  │ 6. Receive DAI
┌─────────────┐                                        │
│  ETH/USDC   │  2. Transfer USDC ──────┐             │
│    Pool     │                          │             │
└─────────────┘                          v             │
                                   ┌─────────────┐     │
                                   │  USDC/DAI   │     │
                                   │    Pool     │─────┘
                                   └─────────────┘  5. Transfer DAI

Total Token Transfers:
1. ETH from user to Pool 1
2. USDC from Pool 1 to Pool 2
3. DAI from Pool 2 to user

= 3 TRANSFERS (expensive!)
```

### V4: Multi-Hop Swap with Flash Accounting
```
                      ┌─────────────────────────┐
                      │     POOL MANAGER        │
                      │                         │
   ┌──────┐           │  ┌─────────────────┐   │      ┌──────┐
   │ USER │──1. ETH──→│  │ 📝 Ledger:      │   │      │ USER │
   │      │           │  │                 │   │      │      │
   │      │           │  │ User: -1 ETH    │   │←─4.──│      │
   │      │           │  │       ↓         │   │  DAI │      │
   └──────┘           │  │ 2. Calc USDC    │   │      └──────┘
                      │  │       ↓         │   │
                      │  │ 3. Calc DAI     │   │
                      │  │                 │   │
                      │  │ User: +100 DAI  │   │
                      │  └─────────────────┘   │
                      │                         │
                      └─────────────────────────┘

Total Token Transfers:
1. ETH from user to PoolManager
2. DAI from PoolManager to user

= 2 TRANSFERS (cheap!)

Steps 2 & 3 are just MATH, no actual token movement!
```

---

## 🔐 The Locking Mechanism

**One-line**: Locking ensures the PoolManager keeps proper track of all debits/credits and makes sure everything balances out before finishing.

Think of it like a bank vault:

```
1. Vault is LOCKED (secure, nothing can happen)
2. Customer wants to do business → UNLOCK vault
3. Customer does multiple transactions (deposits, withdrawals)
4. Bank keeps a ledger of everything
5. End of business → Check if ledger balances out
6. If balanced → LOCK vault
   If NOT balanced → REJECT everything and try again
```

---

## 🎨 Visual: The Lock/Unlock Flow

```
                    POOL MANAGER STATE
                    ═════════════════

Step 1:  ┌────────────┐
         │  🔒 LOCKED │  ← Default state: Safe and secure
         └────────────┘

Step 2:  User calls unlock()
         ↓
         ┌──────────────┐
         │  🔓 UNLOCKED │  ← Work can happen now!
         └──────────────┘
         ↓
         ┌─────────────────────────────────┐
         │  📋 Balance Delta Ledger:       │
         │  (Tracks debits & credits)      │
         │                                  │
         │  Token A: 0                      │
         │  Token B: 0                      │
         │  ...                             │
         └─────────────────────────────────┘

Step 3:  Execute operations (swap, add liquidity, etc.)
         ↓
         ┌─────────────────────────────────┐
         │  📋 Balance Delta Ledger:       │
         │                                  │
         │  ETH:  -1.0   (user owes)       │
         │  USDC: +1000  (user gets)       │
         └─────────────────────────────────┘

Step 4:  Settle balances (transfer tokens)
         ↓
         ┌─────────────────────────────────┐
         │  📋 Balance Delta Ledger:       │
         │                                  │
         │  ETH:  0   ✅                    │
         │  USDC: 0   ✅                    │
         └─────────────────────────────────┘

Step 5:  Check: All balances = 0?
         ↓
      ✅ YES → LOCK vault
      ❌ NO  → REVERT transaction

         ┌────────────┐
         │  🔒 LOCKED │  ← Back to secure state
         └────────────┘
```

---

## 💻 Code Breakdown: The Unlock Function

```solidity
function unlock(bytes calldata data) external returns (bytes memory result) {
    // 1. Safety check: Make sure we're not already unlocked
    if (Lock.isUnlocked()) revert AlreadyUnlocked();

    // 2. Unlock the PoolManager
    Lock.unlock();

    // 3. Call back to the caller to do their work
    //    (This is where swaps, liquidity changes, etc. happen)
    result = IUnlockCallback(msg.sender).unlockCallback(data);

    // 4. Check that all balances are settled (net zero)
    if (NonZeroDeltaCount.read() != 0) revert CurrencyNotSettled();

    // 5. Lock the PoolManager again
    Lock.lock();
}
```

**Think of it like a secure door**:
1. Check door isn't already open
2. Unlock door
3. Let person do their business inside
4. Check they didn't leave a mess (unsettled balances)
5. Lock door again

---

## 🎨 Visual: Complex Example - Swap with Hook

Let's say a pool has a hook that does a SECOND swap every time a user swaps:

```
USER                PERIPHERY         POOL MANAGER        HOOK
  │                     │                    │              │
  │ 1. Initiate Swap    │                    │              │
  ├────────────────────→│                    │              │
  │                     │                    │              │
  │                     │ 2. unlock()        │              │
  │                     ├───────────────────→│              │
  │                     │                    │              │
  │                     │ 3. unlockCallback()│              │
  │                     │←───────────────────┤              │
  │                     │                    │              │
  │                     │ 4. swap()          │              │
  │                     ├───────────────────→│              │
  │                     │                    │              │
  │                     │                    │ 5. beforeSwap│
  │                     │                    ├─────────────→│
  │                     │                    │←─────────────┤
