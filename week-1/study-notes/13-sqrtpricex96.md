# sqrtPriceX96 - Square Root Price Representation

**Date**: January 22, 2026 (Week 1 - Day 2)

---

## What is sqrtPriceX96?

**One-line**: sqrtPriceX96 is the square root of a token price, represented in Q64.96 format, used for gas-efficient price calculations.

**Simple Explanation**:
Instead of storing prices directly (like $1000), Uniswap stores the square root of prices (√$1000 = 31.62...) in Q64.96 format. This makes complex math much simpler and cheaper on-chain.

---

## Why Square Root?

### The Problem with Direct Prices
```
Computing liquidity needs LOTS of math:

Area of Liquidity Rectangle:
  L = Δx × Δy

Where:
  Δx = change in Token X
  Δy = change in Token Y

This requires:
  - Multiplication
  - Division
  - Square roots
  = Expensive gas!
```

### The Solution: Use √P Instead
```
With square roots, the math simplifies:

  L = Δx × √P

OR

  L = Δy / √P

Much simpler calculations = Lower gas! 🦄
```

---

## The Full Name Breakdown

```
sqrtPriceX96
│││  │   │││
│││  │   │└└─ 96 bits for decimals
│││  │   └─── X = "times" (multiplied by)
│││  └────── Price
││└───────── Square root
│└────────── Variable name style
└─────────── Solidity naming

Translation:
"Square root of price, multiplied by 2^96"
```

---

## Converting Price to sqrtPriceX96

### Step-by-Step Process

```
CONVERSION FLOW
═══════════════

Regular Price (P)
       ↓
Take Square Root (√P)
       ↓
Convert to Q64.96 (× 2^96)
       ↓
sqrtPriceX96
```

### Example: ETH = $1000

```
Step 1: Start with price
  P = 1000 USDC per ETH

Step 2: Take square root
  √P = √1000
  √P ≈ 31.6228

Step 3: Convert to Q64.96
  sqrtPriceX96 = 31.6228 × 2^96
  sqrtPriceX96 = 2,505,414,483,750,824,843,905,891,325,952

Final: sqrtPriceX96 = 2,505,414,483,750,824,843,905,891,325,952
```

