# Week 5 Practice: Dynamic Fees Exercises

**Goal**: Reinforce dynamic fee concepts from the gas-price and Nezlobin lessons.

---

## Exercise 1: Explain the Two Dynamic Fee Paths

Write a short explanation of the difference between:
- `poolManager.updateDynamicLPFee(...)`
- fee override returned from `beforeSwap` with `OVERRIDE_FEE_FLAG`

Checklist:
- Which one is better for per-swap decisions?
- Which one updates persistent pool state?
- What pool configuration is required?

---

## Exercise 2: Build the Gas-Price Hook From Memory

Implement a hook with:
- `beforeInitialize`
- `beforeSwap`
- `afterSwap`

Must include:
- moving average gas price state
- `BASE_FEE`
- fee adjustments based on +/-10% threshold
- `MustUseDynamicFee` revert

Stretch:
- add events for gas sample updates and fee decisions

---

## Exercise 3: Expand Gas Sampling Coverage

The class example only updates moving average in constructor and `afterSwap`.

Task:
- identify more hook points where gas samples could be collected
- explain tradeoffs (gas cost vs accuracy)

Suggested output:
- a table of hook function -> pros / cons

---

## Exercise 4: Directional Fee Design (No Code)

Given:
- base fee `f`
- tick change `Delta`

Design a rule for:
- increasing fees in one direction
- decreasing in the other
- preventing negative fees

Answer format:
1. Inputs tracked per pool
2. Update timing (top-of-block logic)
3. Fee formulas
4. Safety checks

---

## Exercise 5: Foundry Test Plan (Economic Behavior)

Write a test plan for a directional fee hook that verifies:
- fee changes only after new block detection
- buy/sell direction gets different fees
- no negative fee edge case
- fee override flag is correctly set

---

## Personal Reflection Prompt

Write 5-10 lines on:
- what part of Week 5 was "mechanism design" vs "Solidity implementation"
- what confused you most
- what you want to prototype next

