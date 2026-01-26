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

Step 1: Multiply by 2^96
  100 × 2^96 = 100 × 79,228,162,514,264,337,593,543,950,336

Result (Q64.96):
  7,922,816,251,426,433,759,354,395,033,600

To get back to 100:
  7,922,816,251,426,433,759,354,395,033,600 ÷ 2^96 = 100
```

**Example 2: Converting 0.5 to Q64.96**
```
Actual number: 0.5

Step 1: Multiply by 2^96
  0.5 × 2^96 = 0.5 × 79,228,162,514,264,337,593,543,950,336

Result (Q64.96):
  39,614,081,257,132,168,796,771,975,168

To get back to 0.5:
  39,614,081,257,132,168,796,771,975,168 ÷ 2^96 = 0.5
```

---

## Visual: Number Representation

```
DIFFERENT NUMBER SYSTEMS
═══════════════════════════

Decimal (What humans use):
  1234.567
  │ │  │││
  │ │  └└└─ Thousandths, etc.
  │ └────── Ones
  └──────── Thousands

Q64.96 (What Uniswap uses):
  7922816251426433759354395033600
  │
  └─ Represents price after × 2^96
     Divide by 2^96 to get real price
```

---

## Converting: Decimal ↔ Q64.96

### Decimal to Q64.96

```
Formula: Q64.96 = decimal × 2^96

Example: Convert 1.5 to Q64.96

Step 1: Write the decimal
  decimal = 1.5

Step 2: Multiply by 2^96
  Q64.96 = 1.5 × 79,228,162,514,264,337,593,543,950,336

  Q64.96 = 118,842,243,771,396,506,690,315,925,504

Verification:
  118,842,243,771,396,506,690,315,925,504 ÷ 2^96
  = 1.5 ✅
```

### Q64.96 to Decimal

```
Formula: decimal = Q64.96 ÷ 2^96

Example: Convert Q64.96 value to decimal

Given: 79,228,162,514,264,337,593,543,950,336

Step 1: Divide by 2^96
  decimal = 79,228,162,514,264,337,593,543,950,336 ÷ 2^96

  decimal = 1.0 ✅
```

---

## Why 96 Bits for Decimals?

```
PRECISION COMPARISON
═══════════════════════

Regular decimal (16 digits):
  Precision: 0.0000000000000001

Q64.96 (96 bits):
  Precision: 1 / 2^96
  ≈ 0.00000000000000000000000000001263

Q64.96 is MUCH more precise! 🦄
```

**Benefits**:
- Handles tiny price differences
- No rounding errors accumulate
- Perfect for high-value pools

---

## Math Operations with Q64.96

### Addition (Easy)
```
If both numbers in Q64.96:

  a_Q = 100 × 2^96
  b_Q = 50 × 2^96

Addition:
  result_Q = a_Q + b_Q
  result_Q = (100 + 50) × 2^96
  result_Q = 150 × 2^96 ✅

Just add directly!
```

### Multiplication (Careful!)
```
If both numbers in Q64.96:

  a_Q = 100 × 2^96
  b_Q = 50 × 2^96

Multiplication:
  result_Q = (a_Q × b_Q) ÷ 2^96
           = (100 × 2^96) × (50 × 2^96) ÷ 2^96
           = 5000 × 2^96 ✅

Must divide by 2^96 to fix scale!
```

### Division (Careful!)
```
If both numbers in Q64.96:

  a_Q = 100 × 2^96
  b_Q = 50 × 2^96

Division:
  result_Q = (a_Q × 2^96) ÷ b_Q
           = (100 × 2^96 × 2^96) ÷ (50 × 2^96)
           = 2 × 2^96 ✅

Must multiply by 2^96 to fix scale!
```

---

## Practical Example

**Scenario**: Calculate price in Uniswap pool

```
Pool: ETH/USDC
Reserve0 (ETH): 10 ETH
Reserve1 (USDC): 10,000 USDC

Human calculation:
  price = 10,000 ÷ 10 = 1000 USDC per ETH

Uniswap V4 calculation (Q64.96):

Step 1: Convert reserves to Q64.96
  reserve0_Q = 10 × 2^96
  reserve1_Q = 10,000 × 2^96

Step 2: Calculate price
  price_Q = (reserve1_Q × 2^96) ÷ reserve0_Q
  price_Q = (10,000 × 2^96 × 2^96) ÷ (10 × 2^96)
  price_Q = 1000 × 2^96

Step 3: Convert back to decimal
  price = price_Q ÷ 2^96
  price = 1000 USDC per ETH ✅
```

---

## Common Pitfalls

### Pitfall 1: Forgetting the Scale
```
❌ Wrong:
  result = a_Q × b_Q
  (Result is scaled by 2^192, not 2^96!)

✅ Correct:
  result = (a_Q × b_Q) ÷ 2^96
```

### Pitfall 2: Mixing Formats
```
❌ Wrong:
  result = Q64_96_value + regular_decimal
  (Can't mix formats!)

✅ Correct:
  regular_as_Q = regular_decimal × 2^96
  result = Q64_96_value + regular_as_Q
```

### Pitfall 3: Overflow
```
❌ Risk:
  huge_number × 2^96
  (Might exceed 256 bits!)

✅ Safety:
  Check: value < 2^160 before converting
  Use Solidity's SafeMath
```

---

## Code Example

```solidity
// Convert decimal to Q64.96
function toQ64_96(uint256 value) internal pure returns (uint256) {
    return value * (2 ** 96);
}

// Convert Q64.96 to decimal
function fromQ64_96(uint256 valueQ) internal pure returns (uint256) {
    return valueQ / (2 ** 96);
}

// Multiply two Q64.96 numbers
function mulQ64_96(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
{
    return (a * b) / (2 ** 96);
}
