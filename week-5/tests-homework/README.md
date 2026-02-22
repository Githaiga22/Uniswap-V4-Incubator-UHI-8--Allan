# Week 5 Tests / Homework (Dynamic Fees)

**Author**: Allan Robinson
**Week**: 5
**Topic**: Dynamic Fee Hooks

---

## Recommended Homework Deliverables

### Option A (Core): Gas-Price Dynamic Fee Hook

Build and test a hook that:
- enforces dynamic-fee pool initialization
- tracks moving average gas price
- returns per-swap fee override in `beforeSwap`
- updates moving average in `afterSwap`

Minimum tests:
- constructor initializes moving average
- base fee case (gas ~= average)
- higher fee case (gas below average threshold)
- lower fee case (gas above average threshold)

---

### Option B (Stretch): Directional Fee Prototype

Prototype a directional fee hook that:
- tracks per-pool block/tick state
- computes tick delta at top of block
- returns different fees by swap direction

Minimum tests:
- top-of-block detection works
- directional fee flips when delta sign flips
- fee never goes negative

---

## Suggested File Layout (if building)

```text
tests-homework/
├── src/
│   ├── GasPriceFeesHook.sol
│   └── DirectionalFeeHook.sol         # optional stretch
├── test/
│   ├── GasPriceFeesHook.t.sol
│   └── DirectionalFeeHook.t.sol       # optional stretch
├── foundry.toml
└── README.md
```

---

## Submission Checklist

- [ ] Notes reviewed
- [ ] Hook compiles
- [ ] Tests pass
- [ ] Dynamic fee override flag used correctly
- [ ] README explains mechanism design assumptions
- [ ] Edge cases documented

---

## My Progress Status

- [x] Week 5 notes captured
- [x] Resource links collected
- [ ] Gas-price hook rebuilt locally (next)
- [ ] Directional fee prototype started

