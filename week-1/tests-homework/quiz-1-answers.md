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

**What is the main benefit of Flash Accounting in v4?**

### ✅ Answer: C - Avoids intermediate token transfers in multi-hop swaps

### Why?

```
WITHOUT Flash Accounting (V3):
ETH → USDC → DAI

Step 1: Transfer ETH
Step 2: Transfer USDC ← (Extra transfer!)
Step 3: Transfer DAI

= 3 transfers

WITH Flash Accounting (V4):
ETH → USDC → DAI

Step 1: Transfer ETH
Step 2: [Math only, no transfer]
Step 3: Transfer DAI

= 2 transfers (USDC skipped!)
```

**Explanation**: Flash accounting tracks balance deltas internally. Intermediate tokens in a multi-hop swap never actually move - only start and end tokens transfer.

**Why others are wrong**:
- A: Can't do infinite swaps, still limited by balances
- B: Custom fees come from hooks, not flash accounting
- D: Batching happens at router level, not flash accounting

---

## Question 3: Transient Storage

**What EIP introduced transient storage and what is its key benefit?**

### ✅ Answer: C - EIP-1153; low-gas ephemeral storage

### Why?

