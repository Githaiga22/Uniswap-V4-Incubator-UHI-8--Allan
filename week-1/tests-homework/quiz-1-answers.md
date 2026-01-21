# Quiz 1: Uniswap V4 Architecture & Hooks - Answer Key

**Date**: January 20, 2026 (Week 1)

---

## Question 1: Singleton PoolManager

**What is the primary reason Uniswap v4 uses a singleton PoolManager instead of deploying a new contract per pool like v3?**

### ✅ Answer: C - To lower gas costs and improve composability

### Why?

```
V3 (Multiple Contracts):
┌─────┐  ┌─────┐  ┌─────┐
│Pool1│  │Pool2│  │Pool3│
└─────┘  └─────┘  └─────┘
External calls = EXPENSIVE

V4 (Singleton):
┌─────────────────┐
│  PoolManager    │
│  ├─ Pool1       │
│  ├─ Pool2       │
│  └─ Pool3       │
└─────────────────┘
Internal calls = CHEAP
```

**Explanation**: Singleton design enables:
- Internal function calls (not external) = less gas
- Multi-hop swaps without moving tokens between contracts
- All pools share same infrastructure

**Why others are wrong**:
- A: Side effect, not primary reason
- B: Code readability isn't the goal
- D: Flash loans existed in V3 too

---

## Question 2: Flash Accounting
