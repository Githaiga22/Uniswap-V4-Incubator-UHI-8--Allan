# PointsHook Implementation Notes

**Author**: Allan Robinson
**Date**: January 27, 2026
**Context**: Week 2 - Advanced Hook Patterns

---

## Concept

PointsHook implements a loyalty rewards system for both traders and liquidity providers. Users earn points for interacting with pools, tracked per-user per-pool.

This is production-grade architecture showing how to build hooks with real business logic.

---

## Architecture

```
Multi-Hook Integration:
┌──────────────────────────────┐
│    User Actions              │
├──────────────────────────────┤
│                              │
│  Swap         Add Liquidity  │
│   │               │          │
│   ▼               ▼          │
│ afterSwap   afterAddLiquidity│
│   │               │          │
│   ├─ Award        ├─ Award   │
│   │  100 pts      │  200 pts │
│   │               │          │
│   ▼               ▼          │
│ Update State:                │
│ userPoints[user][pool] += pts│
│                              │
└──────────────────────────────┘
```

---

## Key Implementation Decisions

### 1. Nested Mapping Structure

```solidity
mapping(address => mapping(PoolId => uint256)) public userPoints;
```
