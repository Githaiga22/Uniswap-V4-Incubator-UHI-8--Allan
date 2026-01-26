# Q64.96 Fixed-Point Numbers

**Date**: January 22, 2026 (Week 1 - Day 2)

---

## What Are Q64.96 Numbers?

**One-line**: Q64.96 is a fixed-point number format using 64 bits for integers and 96 bits for decimals, totaling 160 bits.

**Simple Explanation**:
Regular computers can't do decimal math directly - they only understand whole numbers (integers). Q64.96 is a clever trick to represent decimals using only integers.

Think of it like representing money in cents instead of dollars:
- $10.50 → 1050 cents (integer!)
- $0.99 → 99 cents (integer!)

Q64.96 does the same thing, but way more precise.

---

## The Problem: No Decimals in Solidity

```
WHAT WE WANT:
price = 1000.5 ETH/USDC

WHAT SOLIDITY SEES:
❌ Error: No floating point numbers!
```

### Why This Matters
```
Token Prices:
  ETH/USDC: $1,234.56
  USDC/DAI: $0.9998
  WBTC/ETH: $14.7823

All these have decimals!
But blockchain math needs integers!
```

---

## Q64.96 Breakdown

```
Q64.96 NUMBER STRUCTURE
═══════════════════════

Total: 160 bits (20 bytes)

┌─────────────┬─────────────────────┐
│   64 bits   │      96 bits        │
│  (Integer)  │  (Fractional)       │
├─────────────┼─────────────────────┤
│   Q64       │       .96           │
│  Whole #    │    Decimals         │
└─────────────┴─────────────────────┘

64 bits for integer part:
  Range: 0 to 18,446,744,073,709,551,615

96 bits for decimal part:
  Precision: 2^96 divisions
  ≈ 79,228,162,514,264,337,593,543,950,336
```

---

## How Q64.96 Works

### The Magic Formula

```
Q64.96_value = actual_number × 2^96
```

**Example 1: Converting 100 to Q64.96**
```
Actual number: 100

