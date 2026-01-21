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
