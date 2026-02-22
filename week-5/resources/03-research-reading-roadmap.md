# Week 5 Research Reading Roadmap (Deep Dive)

**Goal**: Move from workshop understanding to mechanism-design fluency for dynamic fees.

---

## Reading Sequence (Recommended)

### Phase 1: Rebuild Core Mental Model

1. `week-5/study-notes/01-dynamic-fees-gas-price-hook.md`
2. `week-5/study-notes/02-nezlobins-directional-fee.md`
3. `week-5/study-notes/03-dynamic-fees-deep-dive-production-notes.md`

Outcome:
- understand dynamic fees mechanically and conceptually

---

## Phase 2: Official Protocol References

Read in this order:
1. Uniswap v4 hooks docs
2. Uniswap v4 hook quickstart setup docs
3. `v4-core` `PoolManager` + `LPFeeLibrary`
4. `v4-periphery` `BaseHook`

Questions to answer while reading:
- Where is dynamic fee validation enforced?
- What makes a pool "dynamic fee enabled"?
- Which hook return value actually overrides the fee?

---

## Phase 3: Nezlobin Mechanism Research

Read in this order:
1. Toxic order flow article
2. Uniswap resilience article
3. Solving order flow toxicity article
4. Range orders article (optional but useful for market microstructure intuition)

Questions to answer:
- Why do AMMs remain inefficient around fee bands?
- Why are large uninformed trades less competitive on AMMs vs CEXs?
- How does directional fee change incentives without changing AMM math?

---

## Phase 4: Simulation / Implementation Thinking

Use:
- `https://github.com/alexnezlobin/simulations`

Focus on:
- parameter sensitivity
- assumptions
- what metrics are used to measure success

Write down:
- what you would change for Uniswap v4 hook constraints
- what signals are feasible onchain vs offchain

---

## Phase 5: Prototype Plan

Create two prototypes:

### Prototype A (Simple)
- gas-price dynamic fee hook
- deterministic thresholds
- per-swap override

### Prototype B (Directional)
- per-block tick delta tracking
- directional fee asymmetry
- bounded fee adjustments

---

## Output I Want From This Roadmap

By the end, I should be able to produce:
- a documented directional fee hook design
- a test plan for edge cases and economics
- a short memo explaining why my chosen parameters are reasonable

