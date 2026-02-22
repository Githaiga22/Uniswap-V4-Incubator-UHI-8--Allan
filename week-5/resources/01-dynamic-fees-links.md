# Week 5 Resources: Dynamic Fees (Web-Checked)

**Compiled**: February 22, 2026
**Topic**: Gas-Price Dynamic Fee Hook + Nezlobin Directional Fee

---

## Core Lesson Code / Repos

### 1. Gas Price Hook (reference implementation)
- Link: https://github.com/haardikk21/gas-price-hook
- Why it matters: Reference code for the class exercise on gas-price-based dynamic fees
- What to review:
  - hook permissions (`beforeInitialize`, `beforeSwap`, `afterSwap`)
  - moving average gas price logic
  - fee override with `OVERRIDE_FEE_FLAG`
  - Foundry tests using `vm.txGasPrice(...)`

### 2. Nezlobin Simulations (research prototype)
- Link: https://github.com/alexnezlobin/simulations
- Why it matters: Simulation repo used to evaluate directional-fee ideas and LP outcomes
- What to review:
  - simulation assumptions
  - fee adjustment parameter choices
  - performance metrics (LP loss / fee revenue changes)

---

## Nezlobin Reading List (Original Blogs)

### 3. Toxic Order Flow on DEXs: Problem and Solutions
- Link: https://medium.com/@alexnezlobin/toxic-order-flow-on-decentralized-exchanges-problem-and-solutions-a1b79f32225a
- Focus:
  - defines toxic order flow
  - explains why arbitrage flow can harm LPs
  - motivates dynamic fee mechanisms

### 4. How Resilient Is Uniswap v3?
- Link: https://medium.com/@alexnezlobin/how-resilient-is-uniswap-v3-81bc548a0312
- Focus:
  - market resilience comparison
  - AMM vs CEX behavior after large trades
  - why splitting orders behaves differently on AMMs

### 5. Executing Large Trades with Range Orders on Uniswap v3
- Link: https://medium.com/@alexnezlobin/executing-large-trades-with-range-orders-on-uniswap-v3-a4a5e4debb67
- Focus:
  - execution quality for large trades
  - range-order mechanics
  - practical behavior of concentrated liquidity

### 6. Solving Order Flow Toxicity
- Link: https://medium.com/@alexnezlobin/solving-order-flow-toxicity-d388126cf69a
- Focus:
  - directional fee intuition
  - mechanism rationale
  - LP protection vs market efficiency tradeoffs

---

## Additional Reference (Author / Research Page)

### 7. Alexander Nezlobin Research Page
- Link: https://sites.google.com/site/alexanderanezlobin/alexander-nezlobin
- Why it matters: useful for finding papers and broader context behind the mechanism design

---

## How I’m Using These Resources

### For Coding
- Use `gas-price-hook` repo as implementation reference
- Rebuild locally from scratch from memory
- Compare my version against the repo only after tests pass

### For Mechanism Design
- Read Nezlobin posts in this order:
  1. Toxic order flow problem
  2. Uniswap resilience
  3. Solving order flow toxicity
  4. Range-order execution (optional deep dive)

### For Future Hook Ideas
- Use simulation repo to understand what parameters matter before shipping a directional fee hook

---

## Notes (Web Verification)

These links were checked during preparation of Week 5 notes (February 22, 2026) and are included because they were directly referenced in the class material.

