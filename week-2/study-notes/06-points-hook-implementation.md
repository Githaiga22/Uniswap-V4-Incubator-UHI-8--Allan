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
function getUserPoints(address user, PoolId poolId) external view returns (uint256) {
    return userPoints[user][poolId];
}

function getTotalPoints(address user) external view returns (uint256) {
    // Note: Can't implement efficiently on-chain
    // Requires off-chain indexing or enumeration
    revert("Use indexer");
}
```

**Design tradeoff**: I made `getUserPoints` view-only for specific pools. Getting total points across ALL pools can't be done efficiently on-chain without tracking a user's pool list (expensive).

**Solution**: Frontend should use event indexing (The Graph, etc.) to aggregate total points.

### 5. Missing: msg.sender Extraction

```solidity
function _afterSwap(...) internal override returns (bytes4, int128) {
    // TODO: Need to extract user address
    // msg.sender in this context is PoolManager, not user

    PoolId poolId = key.toId();
    // userPoints[???][poolId] += POINTS_PER_SWAP;

    return (BaseHook.afterSwap.selector, 0);
}
```

**Critical learning**: Inside hook callbacks, `msg.sender` is always the PoolManager. The actual user address must be:
1. Passed via `hookData` parameter, OR
2. Extracted from swap router context, OR
3. Tracked via custom router wrapper

**Tom's recommendation**: Use `hookData` to pass user address from router.

---

## What I Learned

**Nested Mappings**: Essential pattern for per-user tracking. First time I've designed storage for multi-dimensional lookups at scale.

**View Functions**: Providing query functions makes hooks frontend-friendly. Without them, dApps can only listen to events.

**Constants vs Config**: Using constants is educational but limiting. Real hooks need governance or admin control to adjust incentives.

**The msg.sender Problem**: Biggest gotcha. Hooks don't directly see end users. Need explicit user identification strategy.

**Permission Granularity**: Can enable many hooks without issues. The address mining scales fine up to ~10 permissions.

---

## Testing Approach

Same setup as MyFirstHook but with additional test cases:

```solidity
// Test cases needed:
1. testSwapAwardsPoints
2. testAddLiquidityAwardsPoints
3. testRemoveLiquidityAwardsPoints
4. testDonateAwardsPoints
5. testMultipleUsersIndependentPoints
6. testSameUserMultiplePools
7. testQueryFunctions
```

**Current blocker**: Need to implement user address passing via hookData before tests can work.

---

## Production Roadmap

To make this production-ready:

### Phase 1: Core Functionality
- [ ] Implement user address extraction via hookData
- [ ] Add events for all point awards
- [ ] Write comprehensive tests
- [ ] Deploy to testnet

### Phase 2: Configurability
- [ ] Make point values configurable per pool
- [ ] Add admin functions (pause, adjust rates)
- [ ] Implement point expiry mechanism
- [ ] Add referral bonus system

### Phase 3: Integration
- [ ] Build frontend dashboard for points
- [ ] Create subgraph for point aggregation
- [ ] Design redemption mechanism (points → rewards)
- [ ] Integrate with existing DEX UIs

### Phase 4: Advanced Features
- [ ] Tiered rewards (more points for large trades)
- [ ] Streak bonuses (daily active users)
- [ ] Pool-specific multipliers
- [ ] Governance: Point holders vote on rates

---

## Architecture Comparison

```
MyFirstHook vs PointsHook:

MyFirstHook                    PointsHook
├─ Single mapping              ├─ Nested mapping
├─ 2 hooks (swap only)         ├─ 4 hooks (swap + liquidity)
├─ Global state                ├─ Per-user state
├─ No query functions          ├─ Query functions included
├─ ~60 lines                   ├─ ~100 lines
└─ Beginner complexity         └─ Intermediate complexity
```

PointsHook is what you'd actually build for a real product. MyFirstHook is for learning the mechanics.

---

## Code Location

`src/examples/PointsHook.sol`

**Lines of code**: ~100 (excluding comments)
**Complexity**: Intermediate level
**Gas cost**: Moderate (nested mapping writes)

---

## Open Questions

1. **Point inflation**: What prevents users from creating spam swaps to farm points?
   - Need minimum trade size or anti-sybil mechanism

2. **Point redemption**: How do users spend/claim their points?
   - Separate redemption contract? NFT minting? Token claims?

3. **Cross-pool points**: Should points be pool-specific or universal?
   - Current design: pool-specific. Could add aggregation layer.

4. **Historical tracking**: Do we need point history or just current balance?
   - Events handle history. State only stores current balance for gas efficiency.

---

**Next**: Study hook deployment and address mining mechanics.
