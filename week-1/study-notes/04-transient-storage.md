# Transient Storage (EIP-1153) - Cheap Temporary Memory

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## 🎓 What is Transient Storage?

**One-line**: Super cheap temporary storage that only lasts for one transaction, perfect for tracking things like locks and balance deltas.

**Simple Explanation**:
Imagine you're doing homework:

**Regular Storage (expensive)**: Writing everything in a permanent notebook that you keep forever
- Every time you write something, it costs money
- Even temporary notes stay there forever
- Wastes space and money

**Transient Storage (cheap)**: Writing on a whiteboard
- Write whatever you need during your homework session
- When you're done, erase everything
- Next homework session, start with a clean slate
- Much cheaper because it doesn't stay forever!

---

## 🌍 Real-World Analogy: The Office Workspace

### Traditional Storage: Filing Cabinet
```
┌─────────────────────────────┐
│   FILING CABINET            │
│   (Permanent Storage)       │
├─────────────────────────────┤
│  📁 Important contracts     │ ← Keep forever
│  📁 Employee records        │ ← Keep forever
│  📁 Tax documents           │ ← Keep forever
│  📁 Today's meeting notes   │ ← Why keep this forever?!
│  📁 Lunch order count       │ ← Why keep this forever?!
│  📁 Temp unlock status      │ ← Why keep this forever?!
└─────────────────────────────┘

Cost: HIGH (needs permanent space)
Use for: Things that MUST persist
```

### Transient Storage: Whiteboard
```
┌─────────────────────────────┐
│      WHITEBOARD             │
│   (Temporary Storage)       │
├─────────────────────────────┤
│  📝 Today's task list       │ ← Erase at end of day
│  📝 Meeting attendance      │ ← Erase at end of day
│  📝 Is vault unlocked? ✓   │ ← Erase at end of day
│  📝 Running balance: +$100  │ ← Erase at end of day
└─────────────────────────────┘

Cost: LOW (erases automatically)
Use for: Temporary tracking within a session
```

---

## 🎨 Visual: Storage Types in Ethereum

```
┌──────────────────────────────────────────────────────────┐
│           ETHEREUM VIRTUAL MACHINE (EVM)                 │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  1. STORAGE (Permanent, Most Expensive)                 │
│     ┌─────────────────────────────────────┐            │
│     │ • Persists across transactions      │            │
│     │ • Cost: ~20,000 gas per write       │            │
│     │ • Use: Token balances, user data    │            │
│     └─────────────────────────────────────┘            │
│                                                          │
│  2. MEMORY (Temporary, Moderate Cost)                   │
│     ┌─────────────────────────────────────┐            │
│     │ • Exists only during function call  │            │
│     │ • Cost: ~3 gas per word             │            │
│     │ • Use: Function variables           │            │
│     └─────────────────────────────────────┘            │
│                                                          │
│  3. CALLDATA (Read-only, Cheap)                         │
│     ┌─────────────────────────────────────┐            │
│     │ • Input data for function           │            │
│     │ • Cost: ~4 gas per byte             │            │
│     │ • Use: Function parameters          │            │
│     └─────────────────────────────────────┘            │
│                                                          │
│  4. TRANSIENT STORAGE (New! Temp + Cheap) 🆕            │
│     ┌─────────────────────────────────────┐            │
│     │ • Persists during transaction only  │            │
│     │ • Cost: ~100 gas per write          │            │
│     │ • Use: Locks, deltas, temp flags    │            │
│     │ • Erased after transaction ends     │            │
│     └─────────────────────────────────────┘            │
└──────────────────────────────────────────────────────────┘
```

---

## 💾 Lifespan Comparison

```
Transaction Timeline:
─────────────────────────────────────────────────────────→

┌──────────────────────────────────────────────────────┐
│ Transaction Starts                                   │
│                                                       │
│ ┌─────────────┐  ┌──────────────┐  ┌──────────────┐ │
│ │  MEMORY     │  │  TRANSIENT   │  │   STORAGE    │ │
│ │  Created    │  │  Created     │  │   Exists     │ │
│ └─────────────┘  └──────────────┘  └──────────────┘ │
│       │                  │                  │        │
│       │                  │                  │        │
│       v                  v                  v        │
│  [Do stuff]         [Track temp]      [Save data]   │
│       │                  │                  │        │
│       │                  │                  │        │
└───────┼──────────────────┼──────────────────┼────────┘
        │                  │                  │
┌───────┼──────────────────┼──────────────────┼────────┐
│ Transaction Ends                                     │
│       │                  │                  │        │
│       v                  v                  │        │
│   ❌ ERASED          ❌ ERASED              │        │
│                                             v        │
│                                        ✅ PERSISTS  │
└──────────────────────────────────────────────────────┘
```

---

## 💻 New Opcodes: TSTORE and TLOAD

EIP-1153 introduced two new operations:

### TSTORE (Transient Store)
```
What it does: Write data to transient storage
Cost: ~100 gas
Syntax: tstore(slot, value)
```

### TLOAD (Transient Load)
```
What it does: Read data from transient storage
Cost: ~100 gas
Syntax: tload(slot)
```

Compare to regular storage:
- `SSTORE` (regular store): ~20,000 gas (200× more expensive!)
- `SLOAD` (regular load): ~2,100 gas (21× more expensive!)

---

## 🎨 Visual: How V4 Uses Transient Storage

```
┌───────────────────────────────────────────────────────┐
│  POOL MANAGER - Transient Storage Usage               │
├───────────────────────────────────────────────────────┤
│                                                        │
│  Slot: 0xc090fc...ab23                                │
│  ┌──────────────────────────────────────────────┐    │
│  │  IS_UNLOCKED: true/false                     │    │
│  │  ↑                                            │    │
│  │  Tracks if PoolManager is currently unlocked │    │
│  └──────────────────────────────────────────────┘    │
│                                                        │
│  Slot: 0x1234ab...def9                                │
│  ┌──────────────────────────────────────────────┐    │
│  │  BALANCE_DELTA_COUNT: 2                      │    │
│  │  ↑                                            │    │
│  │  Tracks how many unsettled balances exist    │    │
│  └──────────────────────────────────────────────┘    │
│                                                        │
│  Slot: 0xabcd12...3456                                │
│  ┌──────────────────────────────────────────────┐    │
│  │  CURRENT_DELTA_ETH: -1000000000000000000     │    │
│  │  ↑                                            │    │
│  │  Tracks ETH balance delta                    │    │
│  └──────────────────────────────────────────────┘    │
│                                                        │
│  All of this gets ERASED when transaction ends!       │
└───────────────────────────────────────────────────────┘
```

---

## 💻 Code Example: The Lock Library

Here's the actual code V4 uses for locking:

```solidity
library Lock {
    // The memory slot for the unlock state
    // uint256(keccak256("Unlocked")) - 1
    uint256 constant IS_UNLOCKED_SLOT =
        uint256(0xc090fc4683624cfc3884e9d8de5eca132f2d0ec062aff75d43c0465d5ceeab23);

    // Unlock the PoolManager
    function unlock() internal {
        uint256 slot = IS_UNLOCKED_SLOT;
        assembly {
            tstore(slot, true)  // ← TSTORE opcode!
        }
    }

    // Lock the PoolManager
    function lock() internal {
        uint256 slot = IS_UNLOCKED_SLOT;
        assembly {
            tstore(slot, false)  // ← TSTORE opcode!
        }
    }

    // Check if unlocked
    function isUnlocked() internal view returns (bool unlocked) {
        uint256 slot = IS_UNLOCKED_SLOT;
        assembly {
            unlocked := tload(slot)  // ← TLOAD opcode!
        }
    }
}
```

**Why assembly?**
Solidity doesn't have built-in functions for `tstore`/`tload` yet (they're too new!), so we use low-level assembly to access these opcodes directly.

---

## 🎨 Visual: Lock State Using Transient Storage

```
Transaction Flow:
═══════════════

1. Transaction Starts
   ┌─────────────────────────┐
   │ Transient Storage       │
   │ IS_UNLOCKED: [empty]    │ ← Starts clean
   └─────────────────────────┘

2. unlock() is called
   ┌─────────────────────────┐
   │ Transient Storage       │
   │ IS_UNLOCKED: true ✓     │ ← tstore(slot, true)
   └─────────────────────────┘

3. Do swaps, modify liquidity, etc.
   ┌─────────────────────────┐
   │ Transient Storage       │
   │ IS_UNLOCKED: true ✓     │ ← Still true
   └─────────────────────────┘

4. lock() is called
   ┌─────────────────────────┐
   │ Transient Storage       │
   │ IS_UNLOCKED: false ✗    │ ← tstore(slot, false)
   └─────────────────────────┘

5. Transaction Ends
   ┌─────────────────────────┐
   │ Transient Storage       │
   │ [ERASED]                │ ← Everything cleared!
   └─────────────────────────┘

6. Next Transaction Starts
   ┌─────────────────────────┐
   │ Transient Storage       │
   │ IS_UNLOCKED: [empty]    │ ← Fresh start again!
   └─────────────────────────┘
```

---

## 📊 Gas Cost Comparison

Let's say the PoolManager needs to track the unlock state for 1 transaction:

### Using Regular Storage (Old Way)
```
Write unlock state:  20,000 gas
Read unlock state:    2,100 gas
Write lock state:    20,000 gas
──────────────────────────────
TOTAL:               42,100 gas
```

### Using Transient Storage (New Way)
```
Write unlock state:     100 gas
Read unlock state:      100 gas
Write lock state:       100 gas
──────────────────────────────
TOTAL:                  300 gas

SAVINGS: 99.3% cheaper! 🎉
```

Now imagine this happens across EVERY transaction in V4. The savings add up FAST!

---

## 🚀 Why Transient Storage is Perfect for V4

### What V4 Needs to Track (Temporarily):
1. **Is the PoolManager unlocked?**
   - Only matters during the transaction
   - Reset at the end

2. **Balance Deltas**
   - Only matters during the transaction
   - Settled and reset at the end

3. **Number of Unsettled Currencies**
   - Only matters during the transaction
   - Should be zero at the end

4. **Reentrancy Guards**
   - Only matters during the transaction
   - Reset at the end

**None of this needs to persist after the transaction!**
Using transient storage = MASSIVE gas savings!

---

## 📅 The Waiting Game

**Fun Fact**: Uniswap V4's launch was DELAYED so they could wait for EIP-1153 to be deployed on mainnet!

```
Timeline:
─────────────────────────────────────────────────────────→

2022: V4 development starts
      ↓
2023: EIP-1153 proposed
      ↓
      [V4 waits patiently...]
      ↓
March 2024: Cancun Upgrade (EIP-1153 goes live!) 🎉
      ↓
2024: V4 launches on mainnet
```

**Before EIP-1153**: Developers had to use hacky workarounds and custom Solidity compilers to test hooks locally. Not fun!

**After EIP-1153**: Everything just works with the standard Solidity compiler!

---

## 🔗 Resources & Citations

1. **EIP-1153: Transient Storage Opcodes**
   https://eips.ethereum.org/EIPS/eip-1153

2. **Atrium Academy - Transient Storage Section**
   https://learn.atrium.academy/course/4b6c25df-f4c8-4b92-ab38-a930284d237e/technical-introduction/v4-architecture

3. **Uniswap V4 Lock Library Code**
   https://github.com/Uniswap/v4-core/blob/main/src/libraries/Lock.sol

4. **Ethereum Cancun Upgrade (includes EIP-1153)**
   https://ethereum.org/en/history/#cancun

---

## ✅ Quick Self-Check

1. **What is transient storage?**
   <details>
   <summary>Answer</summary>
   Temporary storage that only exists during a single transaction and gets erased when the transaction ends. It's much cheaper than permanent storage.
   </details>

2. **What are the two new opcodes introduced by EIP-1153?**
   <details>
   <summary>Answer</summary>
   TSTORE (write to transient storage) and TLOAD (read from transient storage).
   </details>

3. **Why does V4 use transient storage for the lock status?**
   <details>
   <summary>Answer</summary>
   The lock status only matters during the transaction. It doesn't need to persist afterwards, so transient storage is perfect and saves gas.
   </details>

4. **How much cheaper is transient storage compared to regular storage?**
   <details>
   <summary>Answer</summary>
   About 99% cheaper! ~100 gas vs ~20,000 gas for writes.
   </details>

5. **What happens to transient storage data after a transaction ends?**
   <details>
   <summary>Answer</summary>
   It gets completely erased. The next transaction starts with a clean slate.
   </details>

---

**Previous**: [Flash Accounting](./03-flash-accounting.md)
**Next**: [ERC-6909 Claims](./05-erc6909-claims.md)
