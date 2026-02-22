# Dynamic Fees Deep Dive: Production Notes and Research Extensions

**Author**: Allan Robinson
**Date**: February 2026
**Topic**: Moving from Demo Dynamic Fees to Production-Ready Design Thinking

---

## Why This Note Exists

The class implementation was intentionally simple (which was the right call for learning).

This note captures the "next step" questions I should ask before deploying any dynamic fee hook in production:
- Can users game the fee logic?
- Are my signals reliable enough?
- How do I monitor whether the mechanism is helping LPs?
- What should be configurable vs hardcoded?

---

## 1. Mechanism Design Threat Model (What Could Go Wrong?)

### A. Fee Gaming by Sophisticated Users

In the gas-price-based hook:
- fees decrease when `tx.gasprice` is high relative to moving average

Potential issue:
- a user may deliberately submit a high gas price (or pay priority fee) if the reduced swap fee more than offsets the gas premium

What to check:
- compare total user cost under normal fee vs reduced fee
- include gas, priority fee, and swap size
- test across small / medium / whale-size swaps

### B. Sample Bias in Onchain-Only Signals

If the hook updates moving averages only on certain hook calls:
- the dataset is not "all Ethereum transactions"
- it is "transactions that touched this hook"

This can bias the signal, especially for low-activity pools.

Mitigation ideas:
- collect samples in more hook entry points
- use periodic external feeds (carefully)
- add minimum sample count before enabling aggressive fee changes

### C. Oscillating or Unstable Fee Behavior

Aggressive thresholding can cause:
- fee flipping too frequently
- hard-to-predict trader UX
- noisy outcomes for LPs

Mitigation ideas:
- add hysteresis bands
- smooth using EWMA instead of simple average
- clamp max fee change per block / per swap

---

## 2. Signal Design: What Should Drive Dynamic Fees?

The class gas-price hook uses `tx.gasprice`, which is a great teaching signal.

For deeper designs, possible signals include:
- gas price / priority fee
- realized volatility proxy (tick movement)
- recent swap direction imbalance
- block-level price impact (`Delta tick`)
- oracle deviation from external "efficient" price
- liquidity depth changes

### Signal Selection Heuristic

A good signal should be:
1. hard to manipulate
2. cheap to read
3. correlated with the behavior we want to price
4. stable enough to avoid noise-driven fee churn

---

## 3. Fee Update Patterns: Per-Swap vs Periodic

### Per-Swap Override (`beforeSwap` + `OVERRIDE_FEE_FLAG`)

Best when:
- fee depends on current transaction context
- fee should react instantly

Pros:
- maximum responsiveness
- no need to persist every fee in pool state

Cons:
- more complex reasoning per swap
- easier to accidentally create unstable behavior

### Periodic Pool Fee Update (`updateDynamicLPFee`)

Best when:
- fee changes once per block or slower
- signal is block-aggregated

Pros:
- simpler operational behavior
- easier analytics and observability

Cons:
- less responsive
- may lag rapidly changing conditions

---

## 4. Production Guardrails I Would Add

### Fee Bounds

Always clamp fees:
- `MIN_FEE <= fee <= MAX_FEE`

Even if protocol max allows high values, the hook should set a smaller policy range.

### Rate Limits

Limit how fast fees can move:
- max increase per block
- max decrease per block

This reduces jumpy behavior and makes outcomes easier to reason about.

### Cooldowns

Optional:
- only recompute expensive parameters once per block
- reuse values for remaining swaps in that block

### Fail-Safe Mode

If signal is invalid / stale / impossible:
- fall back to a safe base fee
- emit event for observability

---

## 5. Metrics to Track (To Prove the Mechanism Works)

If I build a real dynamic fee hook, I should not judge success by "it compiles" or "tests pass".

I should track:
- swap count and volume by direction
- average fee charged (overall and by direction)
- LP fee revenue over time
- price deviation persistence (how long pool stays inefficient)
- realized slippage for comparable trade sizes
- arbitrage volume share vs uninformed flow proxy
- revert rate / hook failure rate

These metrics are what convert mechanism design into evidence.

---

## 6. Research Extensions I Want to Explore

### A. EWMA Gas Price Hook

Replace simple moving average with exponential weighted moving average:
- faster adaptation
- less historical inertia

### B. Hybrid Signal Fee Hook

Combine:
- gas price
- recent volatility (`|tickDelta|`)

Idea:
- high volatility + high gas => strongly trader-friendly fee reduction
- low volatility + low gas => LP-favoring fee increase

### C. Directional Fee + Inventory-Aware Fee

Directional fees based on price movement are one layer.

A second layer could respond to the hook/pool inventory skew (carefully) to avoid worsening imbalances.

---

## Personal Takeaway

Week 5 made it obvious that the hard part is not writing Solidity syntax.
The hard part is choosing a fee rule that:
- cannot be trivially gamed
- improves LP outcomes
- still keeps the pool competitive

