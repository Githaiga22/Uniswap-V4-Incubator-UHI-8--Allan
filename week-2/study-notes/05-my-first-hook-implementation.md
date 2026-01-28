# MyFirstHook Implementation Notes

**Author**: Allan Robinson
**Date**: January 27, 2026
**Context**: Week 2 - Building My First Hook with Tom Wade

---

## Concept

MyFirstHook is a simple swap counter that tracks how many swaps occur in each pool. It demonstrates the core hook pattern without unnecessary complexity.

---

## Architecture

```
Pool Lifecycle Event Flow:
┌─────────────┐
│  User calls │
│  swap()     │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│  beforeSwap()   │ ← Hook intercepts
│  (count++)      │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│  Pool executes  │
│  swap logic     │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│  afterSwap()    │ ← Hook intercepts again
│  (log event)    │
└─────────────────┘
```

---

## Key Implementation Decisions

### 1. Permission Selection
I only enabled `beforeSwap` and `afterSwap` because that's all this hook needs. Every enabled permission costs gas during deployment address mining.

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeSwap: true,
        afterSwap: true,
        // Everything else: false
    });
}
```

**Why this matters**: The hook address must have specific bits set based on permissions. More permissions = longer mining time.
