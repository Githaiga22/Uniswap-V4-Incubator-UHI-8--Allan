# Practice Lab 02: Rebuild the Gas-Price Dynamic Fee Hook

**Goal**: Re-implement the class hook from memory, then improve it.

---

## Part A: Rebuild From Memory

Implement `GasPriceFeesHook.sol` with:
- `beforeInitialize`
- `beforeSwap`
- `afterSwap`
- moving average tracking state
- `BASE_FEE`

Rules:
- do not copy the class code at first
- use your notes only
- run tests after writing

---

## Part B: Add Improvements

Add at least two:
- emit event on moving average update
- emit event on selected fee before swap
- clamp fee to min/max policy bounds
- add a minimum sample count before fee changes
- replace simple average with EWMA

---

## Part C: Reflection

Write a short note:
- what was easy to remember
- what you forgot
- what that reveals about your understanding

