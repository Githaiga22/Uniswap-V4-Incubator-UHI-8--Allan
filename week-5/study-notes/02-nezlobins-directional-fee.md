# Dynamic Fees: Nezlobin's Directional Fee

**Author**: Allan Robinson
**Date**: February 2026
**Topic**: Mechanism Design for Reducing Toxic Order Flow

---

## Lesson Objectives

- Understand the relationship between toxic order flow and LP losses
- Learn why AMMs can remain in "inefficient" states because of swap fees
- Understand Nezlobin's Directional Fee mechanism
- Translate the mechanism into a Uniswap v4 hook design

---

## Why This Lesson Matters

This class moved from "how to code a dynamic fee hook" into "how to design a fee mechanism that changes market behavior."

Main idea:
- Use dynamic fees to make harmful order flow more expensive
- Make helpful rebalancing flow cheaper
- Improve LP outcomes without trying to eliminate risk entirely

---

## Impermanent Loss (Quick Recap)

Impermanent loss (IL) is an **opportunity cost** LPs face when asset prices move.

If LPs had simply held tokens instead of providing liquidity, they may have ended with higher value.

Key point from class:
- The goal is **not** to eliminate IL (that would imply risk-free rewards)
- The goal is to **reduce/mitigate** IL while preserving market function

---

## Toxic Order Flow (The Problem)

### Definition

Order flow is "toxic" when it is dominated by well-informed arbitrageurs who trade only when the trade is profitable net:
- swap fees
- gas
- MEV costs

This often means LPs get rebalanced against at unfavorable moments.

### Why AMMs Are Vulnerable

In AMMs:
- adding/removing liquidity changes depth
- but does **not** directly move relative price
- price discovery happens through swaps

Because swaps have fees, arbitrageurs do not rebalance every small deviation.
They only step in when the deviation is large enough to overcome fees and costs.

Result:
- AMM can remain "stuck" in a less efficient price state
- LPs get exposed to more adverse flow
- large uninformed traders get worse execution than on resilient CEX order books

---

## Core Insight: Directional Fee Asymmetric Adjustment

Suppose the AMM mid-price moved in one direction in the previous block.

Directional fee logic says:
- **increase fees** for swaps that continue pushing price further in that same direction (likely toxic continuation)
- **decrease fees** for swaps that push price back toward efficient price (helpful rebalancing)

This keeps total spread conceptually centered around base fee, but makes it **direction-aware**.

### Example Intuition

If token0 price increased last block:
- buying token0 again likely pushes inefficiency further
- selling token0 helps push price back

So:
- fee for buying token0 -> higher
- fee for selling token0 -> lower

This aligns incentives better for LPs.

---

## Results Mentioned in Class (Nezlobin Simulation)

Using a simulation setup (ETH/USDC, base fees, block-wise fee adjustment):
- LP losses were reduced by up to ~13.1%
- total fees earned by LPs increased by up to ~9.2%

Important interpretation:
- not "IL solved"
- but meaningful mitigation and better fee capture

---

## How to Implement This in a v4 Hook (Mechanism -> Code)

The class framed three engineering questions.

### Q1. How do we know we're at top of a new block?

Track a monotonic block marker in storage:
- `block.timestamp` or `block.number`

Pattern:
- store `blockTimestampLast` (or `blockNumberLast`)
- in `beforeSwap`, if current > stored value:
  - this is the first relevant swap in a new block
  - run top-of-block update logic
  - persist new values

For multi-pool support, store mappings keyed by `PoolId`.

### Q2. How do we measure price impact per block (`Delta`)?

Track previous pool price state, e.g.:
- `tickLast` (recommended simple approach)
- or `sqrtPriceX96Last`

At top of new block:
- read current tick from pool
- compute `Delta = currentTick - tickLast`
- update `tickLast = currentTick`

Interpretation:
- `Delta > 0`: token0 price increased
- `Delta < 0`: token1 price increased

### Q3. How do we choose adjustment factor `c` safely?

If fee adjustment is `f ± c * Delta`, fees can go negative if:

```text
f < c * Delta
```

So choose `c` such that:

```text
c < f / Delta
```

Class example:
- choose a fraction such as `c = 0.9 * (f / Delta)` (or other conservative fraction)

Nezlobin simulation reference used a fixed-style coefficient like `0.75` for the adjustment rule in the study setup.

---

## Practical Hook Architecture (Suggested)

### Storage (per pool)

Possible mappings:

```solidity
mapping(PoolId => uint256) public blockTimestampLast;
mapping(PoolId => int24) public tickLast;
mapping(PoolId => int24) public deltaLast;
mapping(PoolId => uint24) public buyFeeAdjustment;
mapping(PoolId => uint24) public sellFeeAdjustment;
```

### `beforeInitialize` / `afterInitialize`

Initialize:
- `blockTimestampLast`
- `tickLast`
- base directional state

### `beforeSwap`

1. Detect new block
2. If new block:
   - compute tick delta from last block
   - compute directional adjustments
   - store them
3. Inspect swap direction (`params.zeroForOne`)
4. Return direction-specific fee override with `OVERRIDE_FEE_FLAG`

---

## Design Tradeoffs and Improvements

### Strengths

- Can be implemented with hooks (no new AMM required)
- Makes fees responsive to observed directional pressure
- Can improve LP economics while keeping trading possible

### Risks / Challenges

- Requires tuning (`c` is sensitive)
- Can be gamed if adjustment logic is too predictable
- Onchain-only signal may be noisy
- Need robust backtesting before production use

### Improvement Ideas (from class)

1. **Oracle-assisted fee adjustment**
   - use low-latency price feeds to estimate efficient market price

2. **Arbitrage-rights auction / sequencing control**
   - advanced design using AVS + sequencing + return delta hooks

3. **Predictable-event dynamic fees (niche pools)**
   - e.g. stETH/ETH periodic rebalance patterns

---

## My Main Takeaways

- This lesson was more about **market microstructure** than Solidity.
- Dynamic fees are powerful because they reshape incentives, not just revenue split.
- Nezlobin's directional fee gave me a clearer mental model for:
  - toxic flow
  - AMM inefficiency persistence
  - why per-direction fees can improve outcomes

