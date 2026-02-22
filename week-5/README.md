# Week 5: Dynamic Fees in Uniswap v4

**Course**: Uniswap v4 Incubator (UHI-8)
**Author**: Allan Robinson
**Week**: 5
**Topic**: Dynamic Fees (Gas-Price Fees + Nezlobin's Directional Fee)

---

## Overview

Week 5 introduced a new category of hooks: **dynamic fee hooks**.

Instead of treating LP fees as static pool configuration, we learned how a hook can:
- adjust fees **per swap** using `beforeSwap`
- update a pool's dynamic LP fee state
- respond to real-world conditions (like gas spikes)
- design fee mechanisms that improve incentives for LPs and traders

This week covered two major ideas:
1. A **gas-price-based fee hook** (fully built and tested)
2. **Nezlobin's Directional Fee** (mechanism design and implementation strategy)

---

## What I Learned This Week

### 1. Dynamic Fees in v4 Are First-Class
- Fees live in pool state (`lpFee` in `Slot0`)
- Hooks can update them if the pool was initialized as a **dynamic fee pool**
- There are two patterns:
  - `poolManager.updateDynamicLPFee(...)` for less frequent updates
  - return fee override with `OVERRIDE_FEE_FLAG` in `beforeSwap` for per-swap updates

### 2. Mechanism Design Matters More Than Code
- Dynamic fees are not just "changing numbers"
- They change who a pool is competitive for:
  - swappers
  - LPs
  - arbitrageurs
- Poor fee logic can be gamed

### 3. Toxic Order Flow Is a Real LP Problem
- Large AMM trades are often dominated by informed arbitrage
- LPs may earn fees but still lose to impermanent loss
- Nezlobin's work shows dynamic fees can reduce LP losses and improve fee capture

---

## Folder Structure

```text
week-5/
├── study-notes/
│   ├── 01-dynamic-fees-gas-price-hook.md
│   ├── 02-nezlobins-directional-fee.md
│   ├── 03-dynamic-fees-deep-dive-production-notes.md
│   └── 04-directional-fee-hook-implementation-blueprint.md
│
├── resources/
│   ├── 01-dynamic-fees-links.md
│   ├── 02-official-docs-and-code-references.md
│   └── 03-research-reading-roadmap.md
│
├── practice/
│   ├── 01-dynamic-fees-exercises.md
│   ├── 02-gas-price-hook-rebuild-lab.md
│   ├── 03-directional-fee-design-lab.md
│   └── 04-backtesting-and-risk-checklist.md
│
├── tests-homework/
│   ├── 01-assignment-overview.md
│   ├── 02-gas-price-hook-test-checklist.md
│   ├── 03-week-5-quiz-and-answers.md
│   └── README.md
│
└── README.md
```

---

## Study Notes Summary

### `01-dynamic-fees-gas-price-hook.md`
- Dynamic fee pool requirements
- `beforeInitialize` validation (`MustUseDynamicFee`)
- Moving average gas price tracking
- Per-swap fee override with `OVERRIDE_FEE_FLAG`
- Foundry setup and testing flow

### `02-nezlobins-directional-fee.md`
- Impermanent loss recap
- Toxic order flow and AMM competitiveness
- Why AMMs get "stuck" around fee spreads
- Directional fee mechanism design
- How to implement per-block delta tracking in a v4 hook

### `03-dynamic-fees-deep-dive-production-notes.md`
- Production considerations and adversarial thinking
- Per-swap vs periodic fee updates tradeoffs
- Gas/oracle/latency design constraints
- Monitoring and metrics to validate fee logic

### `04-directional-fee-hook-implementation-blueprint.md`
- Concrete v4 hook storage design
- Per-block update algorithm
- Directional fee formulas and guards
- Suggested testing matrix and edge cases

### `tests-homework/03-week-5-quiz-and-answers.md`
- Quiz questions from both dynamic fee lessons
- Correct answers with explanations

---

## Progress Notes (My Understanding)

- I now understand the difference between **fee updates in pool state** vs **per-swap fee override**.
- I can explain why `DYNAMIC_FEE_FLAG` must be set at pool initialization.
- I understand how to build a simple dynamic fee hook that reacts to `tx.gasprice`.
- I understand Nezlobin's directional fee as an **incentive design** for reducing toxic flow, not a magic fix for IL.

---

## Next Steps

1. Implement the gas-price hook locally from notes (if not already done)
2. Extend it to track gas prices in more hook entry points
3. Prototype a simplified directional fee hook using tick delta per block
4. Backtest different `c` values against historical swaps
5. Add monitoring metrics before any real deployment

---

## Week 5 Build Quality Improvements (Extra Step Forward)

To go beyond class notes, I also added:
- a production-minded deep-dive note on dynamic fee hook risks and monitoring
- a directional fee implementation blueprint (storage + algorithms + tests)
- a structured practice series (labs + backtesting checklist)
- an expanded resource stack with official docs, code references, and a reading roadmap
