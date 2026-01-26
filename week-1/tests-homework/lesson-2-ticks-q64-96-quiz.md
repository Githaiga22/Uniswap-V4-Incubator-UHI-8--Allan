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
