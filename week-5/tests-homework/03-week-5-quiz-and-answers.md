# Week 5 Quiz Questions and Answers (Dynamic Fees)

**Author**: Allan Robinson
**Date**: February 2026
**Topic**: Dynamic Fees + Nezlobin's Directional Fee

---

## Quiz 1: Gas-Price Dynamic Fees

### Q1. How can a hook update the swap fee for every individual swap (not just once per block)?

- A. By calling `poolManager.updateDynamicLPFee()` in `beforeSwap`
- B. By modifying the `PoolKey`'s fee parameter directly
- C. By returning an override fee with the `OVERRIDE_FEE_FLAG` from `beforeSwap`
- D. Dynamic fees cannot be changed per-swap, only per-block

**Correct Answer: C**

**Why**:
- Per-swap dynamic fee behavior is achieved by returning an override fee from `beforeSwap`
- The override must include the `OVERRIDE_FEE_FLAG`

---

### Q2. What must be true about a pool for a hook to update its LP fees dynamically?

- A. The pool must be initialized with the `DYNAMIC_FEE_FLAG` set
- B. The pool must have at least $1M in TVL
- C. The hook must be the pool owner
- D. The pool must have no existing liquidity positions

**Correct Answer: A**

**Why**:
- Dynamic fee support is decided at pool initialization using the `DYNAMIC_FEE_FLAG`
- It cannot be enabled later for an already-initialized fixed-fee pool

---

## Quiz 2: Nezlobin's Directional Fee

### Q1. What is the primary goal of Nezlobin's Directional Fee mechanism?

- A. To maximize trading volume on the pool
- B. To eliminate all fees for retail traders
- C. To reduce impermanent loss for LPs by making toxic arbitrage more expensive and attracting uninformed traders
- D. To prevent anyone from using the pool

**Correct Answer: C**

**Why**:
- The mechanism aims to improve LP outcomes by penalizing toxic continuation flow and improving the economics of rebalancing/helpful flow

---

### Q2. In Nezlobin's model, if the tick increased (Token 0 price went up) in the previous block, what should happen to fees?

- A. Fees for buying Token 0 should increase, fees for selling Token 0 should decrease
- B. Fees should be the same in both directions
- C. All fees should be set to zero
- D. The pool should be paused until the price stabilizes

**Correct Answer: A**

**Why**:
- Increasing fees in the direction that continues the move discourages toxic continuation
- Decreasing fees in the opposite direction encourages flow that can move price back toward efficient levels

---

## Personal Checkpoint

If I can explain these four answers from memory, then I understand:
- the mechanics of dynamic fee hooks in v4
- why fee asymmetry by direction is useful
- the difference between coding a hook and designing a market mechanism

