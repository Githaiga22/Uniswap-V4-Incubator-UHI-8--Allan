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

**Why nested**:
- First level: User address
- Second level: Pool identifier
- Value: Point balance

**Benefit**: O(1) lookups for any user-pool combination. Scales to millions of users across thousands of pools.

**Alternative considered**: Single mapping with concatenated keys `keccak256(abi.encode(user, poolId))`. Rejected because nested is clearer and gas-equivalent.

### 2. Multi-Hook Registration

Enabled four lifecycle hooks:

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        afterSwap: true,
        afterAddLiquidity: true,
        afterRemoveLiquidity: true,
        afterDonate: true,
        // before* hooks: false (don't need)
    });
}
```

**Design philosophy**: Only use after* hooks. Points should award AFTER successful actions, not before. This prevents gaming via failed transactions.

### 3. Point Economics

```solidity
uint256 public constant POINTS_PER_SWAP = 100;
uint256 public constant POINTS_PER_LIQUIDITY_ADD = 200;
uint256 public constant POINTS_PER_LIQUIDITY_REMOVE = 50;
uint256 public constant POINTS_PER_DONATION = 300;
```

**Rationale**:
- Swaps (100): Base reward for trading activity
- Adding liquidity (200): Encourage LP participation (2x swap reward)
- Removing liquidity (50): Don't penalize, but lower than add
- Donations (300): Highest reward (donations improve pool economics)

**Production todo**: These should be configurable per pool, not constants. Different pools have different risk profiles and should offer different rewards.

### 4. Query Interface

```solidity
