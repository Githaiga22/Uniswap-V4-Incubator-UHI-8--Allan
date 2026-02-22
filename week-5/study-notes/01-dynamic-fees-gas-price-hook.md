# Dynamic Fees: Gas-Price-Based Fee Hook

**Author**: Allan Robinson
**Date**: February 2026
**Topic**: Building a Dynamic Fee Hook in Uniswap v4

---

## Lesson Objectives

- Learn how dynamic fees work in Uniswap v4
- Understand how hooks can change fees per swap
- Build a gas-price-aware dynamic fee hook
- Test fee behavior using Foundry gas price cheatcodes

---

## Introduction

This lesson was my first hands-on implementation of a **dynamic fee hook**.

The idea is simple and practical:
- When gas is unusually high, lower swap fees a bit (help swappers)
- When gas is unusually low, increase swap fees (favor LPs more)
- When gas is around average, charge a base fee

This is not production-grade mechanism design yet, but it is a very good introduction to the concept.

---

## Key Dynamic Fee Concepts in v4

### Where the Fee Lives

In Uniswap v4, the pool's LP fee is part of pool state (`Slot0.lpFee`).

Normally:
- fee is set during pool initialization
- fee stays fixed

For dynamic fee pools:
- hooks can update/override fee values

### Two Ways to Change Fees

1. **Update pool state fee** (less frequent)
   - `poolManager.updateDynamicLPFee(poolKey, newFee)`

2. **Override fee for a single swap** (per-swap control)
   - return fee from `beforeSwap`
   - set `LPFeeLibrary.OVERRIDE_FEE_FLAG`

For this lesson, we use **per-swap override** because fee depends on current gas price at swap time.

---

## Important Requirement: Dynamic Fee Pool Only

This hook must only be attached to a pool initialized with dynamic fees enabled.

Why:
- If the pool is not a dynamic fee pool, fee override/update logic is invalid
- swaps can fail or the hook becomes unusable

### `beforeInitialize` Guard

```solidity
if (!key.fee.isDynamicFee()) revert MustUseDynamicFee();
```

This was a clean pattern: fail early when pool configuration is wrong.

---

## Hook Design (Gas Price Moving Average)

### State Variables

The hook tracks:
- `movingAverageGasPrice`
- `movingAverageGasPriceCount`

This allows incremental averaging:

```text
NewAverage = ((OldAverage * Count) + CurrentGasPrice) / (Count + 1)
```

### Base Fee

```solidity
uint24 public constant BASE_FEE = 5000; // 0.5%
```

Fee behavior:
- gas > average * 1.1  -> fee = half of base fee
- gas < average * 0.9  -> fee = double base fee
- otherwise            -> fee = base fee

---

## Hook Implementation Flow

### 1. Constructor Initializes Moving Average

The constructor calls `updateMovingAverage()` so the hook starts with one tracked sample immediately.

This was a nice insight: deployment itself is a transaction, so we can seed the average from constructor context.

### 2. `beforeSwap`: Calculate and Return Override Fee

The hook:
1. reads `tx.gasprice`
2. compares to moving average
3. computes dynamic fee
4. returns `fee | OVERRIDE_FEE_FLAG`

Pattern:

```solidity
uint24 feeWithFlag = fee | LPFeeLibrary.OVERRIDE_FEE_FLAG;
return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, feeWithFlag);
```

Important detail:
- The hook returns `ZERO_DELTA` because we are not changing token accounting here
- We are only changing the fee used for this swap

### 3. `afterSwap`: Update Moving Average

After swap completes:
- call `updateMovingAverage()`
- store gas price sample for future swaps

This keeps the model adaptive over time.

---

## Foundry Setup Notes

### Project Setup (as taught)

```bash
forge init gas-price-dynamic-fees
cd gas-price-dynamic-fees
forge install Uniswap/v4-periphery
forge remappings > remappings.txt
rm ./**/Counter*.sol
```

### `foundry.toml` Additions

```toml
solc_version = '0.8.26'
evm_version = "cancun"
optimizer_runs = 800
via_ir = false
ffi = true
```

---

## Testing Strategy (What I Learned)

The test intentionally uses `vm.txGasPrice(...)` to simulate different onchain gas environments.

### Why This Matters

Foundry defaults to `0` gas price, which would make this test misleading.

By setting gas prices manually, the test verifies both:
- fee selection behavior
- moving average update logic

### Test Scenario Summary

1. Deploy hook at **10 gwei**
   - moving average = 10 gwei
   - count = 1

2. Swap at **10 gwei**
   - use base fee
   - moving average stays 10 gwei

3. Swap at **4 gwei**
   - higher fee (cheap gas => charge more)
   - moving average becomes 8 gwei

4. Swap at **12 gwei**
   - lower fee (expensive gas => charge less)
   - moving average becomes 9 gwei

5. Compare outputs
   - low fee swap output > base fee swap output > high fee swap output

This test is a great example of verifying **economic behavior**, not just syntax.

---

## Practical Caveats / Notes

### Accuracy Limitation

The hook only observes gas prices when it is called.

So the moving average is:
- not a chain-wide oracle
- only an average of transactions interacting with the hook

For production accuracy, you'd likely update in more hook entry points (or use external data).

### Mechanism Design Risk

If fee reduction becomes too generous:
- a trader may intentionally overpay gas
- but pay less swap fee overall
- creating a perverse incentive

This is why real deployments need modeling and backtesting.

---

## Key Takeaways

- Dynamic fee pools must be initialized with `DYNAMIC_FEE_FLAG`
- Per-swap fee updates are done via `beforeSwap` fee override + `OVERRIDE_FEE_FLAG`
- `beforeSwap` can change fees without changing swap deltas
- `afterSwap` is a good place to update fee model state for future swaps
- Testing dynamic fees requires simulating transaction conditions (like gas price)

