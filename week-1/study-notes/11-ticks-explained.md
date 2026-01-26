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
