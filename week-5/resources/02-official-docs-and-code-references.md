# Week 5 Resources: Official Docs and Code References

**Compiled**: February 22, 2026
**Purpose**: Primary references for implementing and validating dynamic fee hooks

---

## Official Uniswap Documentation

### 1. Uniswap Docs - v4 Concepts / Hooks
- URL: https://docs.uniswap.org/contracts/v4/concepts/hooks
- Why it matters:
  - hook lifecycle model
  - permissions mental model
  - where hooks fit in v4 architecture

### 2. Uniswap Docs - v4 Quickstart / Create a Hook
- URL: https://docs.uniswap.org/contracts/v4/quickstart/hooks/setup
- Why it matters:
  - Foundry project setup patterns
  - dependency installation
  - scaffolding for v4 hook development

---

## Official Uniswap Repositories

### 3. `v4-core` (Protocol contracts)
- URL: https://github.com/Uniswap/v4-core
- Why it matters:
  - `PoolManager`
  - `LPFeeLibrary`
  - `StateLibrary`
  - core fee logic and validation behavior

### 4. `v4-periphery` (Hook utilities and helpers)
- URL: https://github.com/Uniswap/v4-periphery
- Why it matters:
  - `BaseHook`
  - deploy/test helpers
  - patterns used in examples and workshop code

---

## Extra Implementation Reference (Non-Uniswap)

### 5. OpenZeppelin Uniswap Hooks (Fee examples)
- URL: https://docs.openzeppelin.com/uniswap-hooks/fee
- Why it matters:
  - extra perspective on fee-hook design
  - examples of fee customization patterns
  - useful for comparing design choices and guardrails

---

## Local Code Pointers (From This Repo)

For quick lookup while coding in this repo:
- `limit-orders/lib/v4-core/src/PoolManager.sol`
- `limit-orders/lib/v4-core/src/libraries/LPFeeLibrary.sol`
- `limit-orders/lib/v4-core/src/libraries/StateLibrary.sol`
- `limit-orders/lib/v4-core/src/types/PoolKey.sol`
- `limit-orders/lib/v4-periphery/src/utils/BaseHook.sol`

---

## How I Use These Together

1. **Docs first** for concepts and correct mental model
2. **v4-core source** for exact behavior and edge cases
3. **v4-periphery** for hook patterns and helper utilities
4. **OpenZeppelin docs** for alternative implementation ideas

