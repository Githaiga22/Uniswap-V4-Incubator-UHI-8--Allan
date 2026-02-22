# Week 5 Assignment Overview: Dynamic Fee Hooks

**Author**: Allan Robinson
**Week**: 5
**Topic**: Dynamic Fee Hooks (Gas Price + Directional Fee Prototype)

---

## Assignment Goal

Demonstrate understanding of:
- Uniswap v4 dynamic fee mechanics
- hook-based fee overrides in `beforeSwap`
- mechanism design tradeoffs for fee updates
- testing dynamic fee behavior (not just compilation)

---

## Required Deliverable (Core)

Build a gas-price-based dynamic fee hook that:
- validates `DYNAMIC_FEE_FLAG` on pool initialization
- computes per-swap fee override
- sets `OVERRIDE_FEE_FLAG`
- updates moving average after swap

And write tests proving:
- fee changes when gas crosses thresholds
- moving average updates correctly
- lower fee produces better output than higher fee (same liquidity / small size)

---

## Stretch Deliverable

Design or prototype a directional fee hook with:
- per-block delta tracking
- direction-specific fee outputs
- bounded fee adjustment

This can be:
- implementation + tests, or
- a design doc + test plan + pseudocode

