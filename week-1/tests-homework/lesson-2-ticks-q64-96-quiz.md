# Lesson 2: Ticks and Q64.96 Numbers - Quiz

**Date**: January 22, 2026 (Week 1 - Day 2)
**Topics**: Ticks, Q64.96 fixed-point numbers, sqrtPriceX96

---

## Section 1: Conceptual Understanding (Easy)

### Question 1
**What is a tick in Uniswap V4?**

<details>
<summary>Answer</summary>

A tick is a discrete price boundary that represents a 0.01% price change. Ticks divide the continuous price spectrum into manageable segments where liquidity providers can place their capital.

Think of it like markings on a ruler - instead of infinite points, we have specific measurement markers.
</details>

---

### Question 2
**Why does Solidity need Q64.96 numbers instead of regular decimals?**

<details>
<summary>Answer</summary>

Solidity doesn't support floating-point arithmetic. The EVM can only work with integers. Q64.96 is a clever workaround that represents decimals using only integers by multiplying values by 2^96.

Example: $10.50 becomes 1050 cents (integer). Q64.96 does the same but with way more precision.
</details>

---

### Question 3
**What happens to your liquidity position when the price moves below your lower tick?**

<details>
<summary>Answer</summary>

Your entire position converts to Token1 (the quote token, usually USDC/stablecoin) and you stop earning trading fees because your liquidity is no longer active in the current price range.

Example: If you set a range of $900-$1100 for ETH and price drops to $850, you now hold 100% USDC and earn no fees.
</details>

---

### Question 4
**What does the "X96" in sqrtPriceX96 mean?**

<details>
<summary>Answer</summary>

"X96" means "multiplied by 2^96". It indicates the value is in Q64.96 format.

So sqrtPriceX96 = √Price × 2^96

This converts the square root of the price into a high-precision integer that Solidity can work with.
</details>

---

## Section 2: Calculations (Medium)

### Question 5
**Calculate the price from tick = 6931**

<details>
<summary>Answer</summary>

**Formula**: price = 1.0001^tick

**Calculation**:
```
price = 1.0001^6931
price ≈ 2.0000

Result: ~2.0 (approximately double the base price)
```

**Why this matters**: Tick 6931 represents roughly a 100% price increase from the base (tick 0).
</details>

---

### Question 6
**Convert 2.5 to Q64.96 format**

<details>
<summary>Answer</summary>

**Formula**: Q64.96 = decimal × 2^96

**Calculation**:
```
2^96 = 79,228,162,514,264,337,593,543,950,336

2.5 × 2^96 = 2.5 × 79,228,162,514,264,337,593,543,950,336
           = 198,070,406,285,660,843,983,859,875,840

Result: 198,070,406,285,660,843,983,859,875,840
```

**Verification**: Divide by 2^96 to get back 2.5 ✅
</details>

---

### Question 7
**If sqrtPriceX96 = 79,228,162,514,264,337,593,543,950,336, what is the actual price?**

<details>
<summary>Answer</summary>

**Step 1**: Convert from Q64.96 to √P
```
√P = sqrtPriceX96 ÷ 2^96
√P = 79,228,162,514,264,337,593,543,950,336 ÷ 79,228,162,514,264,337,593,543,950,336
√P = 1.0
```

**Step 2**: Square to get price
```
P = (√P)^2
P = (1.0)^2
P = 1.0

Result: Price = 1.0 (1:1 ratio)
```
</details>

---

### Question 8
**What tick spacing would you expect for a 0.30% fee tier pool?**

<details>
<summary>Answer</summary>

**Answer**: Tick spacing = 60

**Fee Tier → Tick Spacing Reference**:
- 0.01% → spacing 1 (very tight, stable pairs)
- 0.05% → spacing 10
- 0.30% → spacing 60 (common tier)
- 1.00% → spacing 200 (volatile pairs)

This means valid ticks are: ..., -120, -60, 0, 60, 120, 180, ...
</details>

---

## Section 3: Practical Application (Technical)

### Question 9
**You want to provide liquidity for ETH/USDC with current price at $2000. You want your range from $1800 to $2200. Calculate the approximate tick values.**

<details>
<summary>Answer</summary>

**Formula**: tick = log(price) / log(1.0001)

**Lower Bound** ($1800):
```
tick_lower = log(1800) / log(1.0001)
tick_lower ≈ 74,408
```

**Upper Bound** ($2200):
```
tick_upper = log(2200) / log(1.0001)
tick_upper ≈ 78,833
```

**With 0.30% fee (spacing = 60)**:
- tick_lower: 74,408 → round to 74,400
- tick_upper: 78,833 → round to 78,840

**Final Range**: Tick 74,400 to 78,840
**Actual Prices**: $1798.65 to $2201.38 ✅
</details>

---

### Question 10
**Multiply two Q64.96 numbers: a = 100 × 2^96 and b = 50 × 2^96. What's the result?**

<details>
<summary>Answer</summary>

**WRONG WAY** ❌:
```
result = a × b
result = (100 × 2^96) × (50 × 2^96)
result = 5000 × 2^192  // WRONG! Scaled by 2^192
```

**CORRECT WAY** ✅:
```
result = (a × b) ÷ 2^96
result = (100 × 2^96) × (50 × 2^96) ÷ 2^96
result = 5000 × 2^96  // Correct!
```

**Why**: Multiplying two Q64.96 numbers doubles the scaling factor. Must divide by 2^96 to restore correct scale.

**Rule**: When multiplying Q64.96 numbers, divide result by 2^96
</details>

---

### Question 11
**You have a position with tick_lower = -1000 and tick_upper = 1000. Current price moves to tick 1200. What's your position composition?**

<details>
<summary>Answer</summary>

**Analysis**:
- Your range: Tick -1000 to 1000
- Current tick: 1200
- **Position is ABOVE upper tick**

**Result**:
```
Composition: 100% Token0 (e.g., ETH)
Token1 (e.g., USDC): 0%

Earning fees: NO ❌
Why: Price moved above your range. All capital converted to Token0.
```

**What happened**: As price rose from your range, the pool swapped your USDC for ETH. Now you're sitting entirely in ETH waiting for price to come back into range.

**Action needed**: Either wait for price to drop back or rebalance your position to a new range.
</details>

---

### Question 12
