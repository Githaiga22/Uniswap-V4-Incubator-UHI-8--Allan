# Ticks in Uniswap V4 - Discrete Price Boundaries

**Date**: January 22, 2026 (Week 1 - Day 2)

---

## What Are Ticks?

**One-line**: Ticks are discrete price boundaries that divide the continuous price spectrum into manageable segments for concentrated liquidity.

**Simple Explanation**:
Imagine a ruler. Instead of measuring at every possible point (which would be infinite), we mark specific intervals like inches or centimeters. Ticks are like those markings on a price ruler - they create specific points where you can place your liquidity.

---

## The Problem Ticks Solve

### Before Ticks (Uniswap V2)
```
Price Range: $0 to Infinity
Your Liquidity: Spread across EVERYTHING

$0 ──────────────────────────────────────────→ ∞
   ███████████████████████████████████████████
   Your $1000 spread across infinite range

Problem:
- Most liquidity never gets used
- Capital inefficient
- Lower fees earned
```

### After Ticks (Uniswap V3/V4)
```
Price Range: You choose specific boundaries

$900      $1000      $1100
  │          │          │
  └────┬─────┴─────┬────┘
      Tick      Tick
     Lower     Upper
       │           │
       └─────┬─────┘
          Your $1000
     Concentrated here!

Result:
- All liquidity active in your range
- Highly capital efficient
- Higher fees earned (when price is in range)
```

---

## Continuous vs Discrete Prices

### Continuous Price Curve (Theory)
```
In mathematics, prices can be ANY value:

Price
  │
  │     ●
  │    ●●
  │   ● ●
  │  ●  ●
  │ ●   ●
  │●     ●
  └────────── Time

Every point on this curve exists
Infinite possible prices between $1000 and $1001
```

### Discrete Price Curve (Reality in Uniswap)
```
In blockchain, we need specific points:

Price
  │
  │     ■
  │
  │   ■
  │
  │ ■
  │      ■
  └────────── Time

Only specific tick prices exist
Prices "jump" from tick to tick
```

**Why discrete?**
- Computers need specific numbers to work with
- Saves gas by not calculating infinite decimals
- Creates predictable boundaries for liquidity

---

## Understanding Lower and Upper Ticks

```
LIQUIDITY POSITION EXAMPLE
═══════════════════════════

Current ETH Price: $1000

Your Position:
┌─────────────────────────────────────────┐
│                                          │
│  Tick Lower: -1000  Tick Upper: +1000   │
│  (Price: $905)      (Price: $1105)      │
│       │                    │             │
│       ▼                    ▼             │
│       ├────────────────────┤             │
│       │   YOUR LIQUIDITY   │             │
│       └────────────────────┘             │
│              │                           │
│              ▼                           │
│        Active when price                 │
│        $905 - $1105                      │
│                                          │
└─────────────────────────────────────────┘
```

### Tick Lower
**Definition**: The minimum price boundary where your liquidity starts being active.

```
Below Tick Lower:
  Price < $905

  Your position: 100% Token1 (USDC)
  Earning fees: NO ❌
  Why: Price too low, all converted to USDC
```

### Tick Upper
**Definition**: The maximum price boundary where your liquidity stops being active.

```
Above Tick Upper:
  Price > $1105

  Your position: 100% Token0 (ETH)
  Earning fees: NO ❌
  Why: Price too high, all converted to ETH
```

### In Range
```
Between Ticks:
  $905 < Price < $1105

  Your position: Mix of ETH and USDC
  Earning fees: YES ✅
  Why: Liquidity actively facilitating swaps
```

---

## Tick Spacing

**Definition**: The minimum distance between usable ticks, determined by pool fee tier.

```
FEE TIER → TICK SPACING
═══════════════════════

0.01% fee → Spacing: 1
├─ Ticks: ..., -2, -1, 0, 1, 2, ...
└─ Very tight, many options

0.05% fee → Spacing: 10
├─ Ticks: ..., -20, -10, 0, 10, 20, ...
└─ Medium spacing

0.30% fee → Spacing: 60
├─ Ticks: ..., -120, -60, 0, 60, 120, ...
└─ Wider spacing

1.00% fee → Spacing: 200
├─ Ticks: ..., -400, -200, 0, 200, 400, ...
└─ Very wide spacing
```

**Why does this matter?**
- Lower fees = tighter control (stable pairs like USDC/USDT)
- Higher fees = wider ranges (volatile pairs like ETH/SHIB)

---

## Calculating Prices from Ticks

### The Magic Formula

```
price = 1.0001^tick
```

**Each tick represents 0.01% price change**

### Examples

```
Tick = 0:
  price = 1.0001^0 = 1
  (1 Token0 = 1 Token1)

Tick = 100:
  price = 1.0001^100 ≈ 1.01005
  (1% price increase)

Tick = -100:
  price = 1.0001^(-100) ≈ 0.99005
  (1% price decrease)

Tick = 10000:
  price = 1.0001^10000 ≈ 2.7183
  (e, the mathematical constant!)
```

---

## Visual: Tick to Price Conversion

```
TICK NUMBER → PRICE
═══════════════════

Negative Ticks (Price < 1):
  -10000 │ $0.37
  -5000  │ $0.61
  -1000  │ $0.905
     -1  │ $0.99990

Zero Tick (Price = 1):
      0  │ $1.00

Positive Ticks (Price > 1):
     +1  │ $1.00010
  +1000  │ $1.105
  +5000  │ $1.649
 +10000  │ $2.718

Formula: price = 1.0001^tick
```

---

## Practical Example: Setting Up a Position

**Scenario**: You want to provide ETH/USDC liquidity
- Current Price: $1000 per ETH
- Your Range: $900 - $1100

### Step 1: Convert prices to ticks
```
Lower Price: $900
  tick_lower = log($900) / log(1.0001)
  tick_lower ≈ -1054

Upper Price: $1100
  tick_upper = log($1100) / log(1.0001)
  tick_upper ≈ 953
```

### Step 2: Adjust for tick spacing
```
If pool has 0.30% fee (spacing = 60):

tick_lower = -1054
  Round to nearest 60: -1080

tick_upper = 953
  Round to nearest 60: 960

Final Range: Tick -1080 to Tick 960
Actual Prices: $895.86 to $1103.57
```

### Step 3: Deposit liquidity
```
Your position is now active between:
  Lower Tick: -1080 ($895.86)
  Upper Tick: 960 ($1103.57)

If ETH price stays in this range:
  ✅ You earn trading fees
  ✅ Your liquidity is being used

If price leaves this range:
  ❌ You stop earning fees
  ❌ Your position is all in one token
```

---

## Why Ticks Matter

```
WITHOUT TICKS (V2):
┌────────────────────────────────┐
│ $1000 spread $0 to infinity    │
│ Used: 5% of capital            │
│ Wasted: 95% of capital         │
│ Annual fees: $50               │
└────────────────────────────────┘

WITH TICKS (V3/V4):
┌────────────────────────────────┐
│ $1000 concentrated $900-$1100  │
│ Used: 95% of capital           │
│ Wasted: 5% (when out of range) │
│ Annual fees: $950              │
└────────────────────────────────┘

Result: 19× more capital efficient! 🦄
```

---

## Common Tick Mistakes

