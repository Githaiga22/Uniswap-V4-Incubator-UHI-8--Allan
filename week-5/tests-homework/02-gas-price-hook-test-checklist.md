# Week 5 Test Checklist: Gas-Price Dynamic Fee Hook

**Purpose**: Keep tests focused on both logic and economics.

---

## Setup Checks

- [ ] Hook deployed with correct permissions
- [ ] Pool initialized with `LPFeeLibrary.DYNAMIC_FEE_FLAG`
- [ ] Constructor seeds moving average (non-zero sample count)
- [ ] Liquidity added before swaps

---

## Functional Tests

- [ ] `beforeInitialize` reverts for non-dynamic fee pool
- [ ] Base fee returned when gas ~= moving average
- [ ] Higher fee returned when gas < average by threshold
- [ ] Lower fee returned when gas > average by threshold
- [ ] Override fee includes `OVERRIDE_FEE_FLAG`

---

## State Update Tests

- [ ] `movingAverageGasPriceCount` increments after swaps
- [ ] moving average formula produces expected values
- [ ] constructor sample + swap samples match expected count

---

## Economic Behavior Tests

Using same params and small swap size:
- [ ] low-fee swap output > base-fee swap output
- [ ] base-fee swap output > high-fee swap output

---

## Edge Cases (Optional but Valuable)

- [ ] moving average very low / very high values
- [ ] threshold boundary exactly at 10%
- [ ] repeated same-gas swaps
- [ ] fee clamp behavior (if added)

