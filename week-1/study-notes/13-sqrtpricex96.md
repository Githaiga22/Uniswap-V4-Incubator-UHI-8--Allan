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

---

## Converting sqrtPriceX96 Back to Price

### Reverse Process

```
REVERSE CONVERSION
══════════════════

sqrtPriceX96
       ↓
Divide by 2^96 (get √P)
       ↓
Square the result (√P)^2
       ↓
Regular Price (P)
```

### Example: Decode sqrtPriceX96

```
Given: sqrtPriceX96 = 2,505,414,483,750,824,843,905,891,325,952

Step 1: Convert from Q64.96
  √P = sqrtPriceX96 ÷ 2^96
  √P = 2,505,414,483,750,824,843,905,891,325,952 ÷ 79,228,162,514,264,337,593,543,950,336
  √P ≈ 31.6228

Step 2: Square to get price
  P = (√P)^2
  P = (31.6228)^2
  P = 1000 ✅

Final: Price = 1000 USDC per ETH
```

---

## Relationship: Tick ↔ √P ↔ sqrtPriceX96

```
THE FULL CHAIN
══════════════

Tick (i)
   ↓ Formula: 1.0001^i
Price (P)
   ↓ Square root
√P
   ↓ Multiply by 2^96
sqrtPriceX96

REVERSE:
sqrtPriceX96
   ↓ Divide by 2^96
√P
   ↓ Square
Price (P)
   ↓ log(P) / log(1.0001)
Tick (i)
```

---

## Visual: All Three Representations

```
SAME POOL STATE, THREE VIEWS
═════════════════════════════

View 1 - Human Readable:
  "1 ETH = 1000 USDC"
  P = 1000

View 2 - Tick Value:
  "Tick = 69,079"
  (Because 1.0001^69079 ≈ 1000)

View 3 - Smart Contract:
  "sqrtPriceX96 = 2,505,414,483,750,824,843,905,891,325,952"
  (Because √1000 × 2^96)
```

---

## Practical Example: Calculating Liquidity Needed

**Scenario**: I have 2 ETH. Current price is 2000 USDC/ETH. I want to provide liquidity from $1500 to $2500. How much USDC do I need?

### The Formula (Don't Worry About Deriving It)

```
Liquidity (L) = Δx × √P_b × √P / (√P_b - √P)

Where:
  Δx = Amount of Token X (ETH) = 2
  P = Current price = 2000
  P_a = Lower bound = 1500
  P_b = Upper bound = 2500

Then:
