# Directional Fee Hook: Implementation Blueprint (v4)

**Author**: Allan Robinson
**Date**: February 2026
**Topic**: Translating Nezlobin's Directional Fee into a Hook Engineering Plan

---

## Goal

Build a dynamic fee hook that:
- tracks per-pool price movement (tick change) on a block basis
- adjusts fees by swap direction
- penalizes continuation flow
- discounts reversing/rebalancing flow

This file is a concrete implementation plan, not final production code.

---

## Hook Permissions (Expected)

Likely permissions:
- `beforeInitialize` or `afterInitialize` (initialize per-pool state)
- `beforeSwap` (compute/return directional fee override)

Optional extensions:
- `afterSwap` (track additional analytics)
- more hooks for richer signals

---

## Storage Design (Per Pool)

```solidity
struct DirectionalFeeState {
    uint40 lastBlockNumberSeen;
    int24 lastTick;
    int24 lastBlockDeltaTick;
    uint24 baseFee;
    uint24 buyFeeForToken0;   // example naming, depends on convention
    uint24 sellFeeForToken0;
}

mapping(PoolId => DirectionalFeeState) public poolState;
```

Notes:
- Use compact types where reasonable to reduce storage footprint
- Naming must clearly define direction conventions (very easy to get wrong)

---

## Initialization Flow

### `beforeInitialize` / `afterInitialize`

At pool initialization:
1. verify pool uses dynamic fees (`DYNAMIC_FEE_FLAG`)
2. read initial tick
3. store:
   - `lastBlockNumberSeen = block.number`
   - `lastTick = initialTick`
   - default directional fees = base fee

---

## Top-of-Block Update Logic (Inside `beforeSwap`)

Pseudocode:

```text
if (block.number > state.lastBlockNumberSeen):
    currentTick = read pool tick
    delta = currentTick - state.lastTick

    state.lastBlockDeltaTick = delta
    state.lastTick = currentTick
    state.lastBlockNumberSeen = block.number

    recompute directional fees from delta
```

This ensures expensive recomputation happens once per block per active pool.

---

## Fee Computation Strategy

Let:
- `f = base fee`
- `d = adjustment derived from |delta|`

Directional rule (conceptual):
- if previous block moved token0 price up:
  - increase fee on trades that buy token0 (continuation)
  - decrease fee on trades that sell token0 (reversal)
- inverse when previous block moved token0 price down

### Safe Bounds

```text
d <= f - minFee
```

Then:
- `feeLow = max(minFee, f - d)`
- `feeHigh = min(maxFee, f + d)`

### Adjustment Function Options

1. **Linear**
   - `d = k * |delta|`
   - simple, easy to reason about

2. **Capped Linear**
   - `d = min(cap, k * |delta|)`
   - safer

3. **Stepwise**
   - low/medium/high fee buckets based on `|delta|`
   - easier for testing and analytics

---

## Mapping Swap Direction to Fee Direction

This is the most error-prone part.

Need a clear convention for:
- what `params.zeroForOne` means economically
- which side is "buying token0" vs "selling token0"
- how tick sign maps to token price movement

Recommendation:
- write unit tests that assert direction mapping with explicit examples
- document conventions directly in code comments once, near fee selection logic

---

## `beforeSwap` Return Shape

The hook returns:
- selector
- `BeforeSwapDeltaLibrary.ZERO_DELTA`
- dynamic fee override with `OVERRIDE_FEE_FLAG`

Pattern:

```solidity
uint24 feeWithFlag = selectedFee | LPFeeLibrary.OVERRIDE_FEE_FLAG;
return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, feeWithFlag);
```

---

## Testing Blueprint

### Unit Tests (Fee Logic)

1. **Initialization requires dynamic fee pool**
2. **No delta => base fee in both directions**
3. **Positive delta => continuation direction fee higher**
4. **Positive delta => reversal direction fee lower**
5. **Negative delta => directionality flips**
6. **Adjustment capped at bounds**
7. **Override flag always set**

### Block-Timing Tests

8. **Same block multiple swaps**
   - recompute once, reuse stored values

9. **Next block swap**
   - recompute directional fees from new tick delta

### Edge Cases

10. **Very small `|delta|`**
11. **Very large `|delta|`**
12. **minFee floor hit**
13. **maxFee cap hit**

---

## Operational Checklist (Before Real Deployment)

- Backtest on historical swap/tick data
- Validate no negative-fee or overflow paths
- Confirm fee direction mapping with explicit examples
- Add events for fee updates (optional but helpful)
- Monitor fee distribution and slippage outcomes post-launch

---

## Personal Note

This blueprint is the bridge between the class mechanism design and an actual hook implementation. It forces me to define:
- state
- timing
- direction conventions
- safety bounds
- tests

That is usually where hidden mistakes show up.

