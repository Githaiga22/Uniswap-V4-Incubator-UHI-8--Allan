# Week 2: Comprehensive Quiz

**Author**: Allan Robinson
**Date**: January 29, 2026
**Topics**: Ticks, Q64.96, Hook Development, Testing & Deployment

---

## Section 1: Ticks and Price Mathematics

### Question 1: What does a "tick" represent in Uniswap v3/v4?

**A)** The TWAP oracle's observation interval used to compute prices
**B)** A point in the price curve where trades can occur
**C)** The pool's fee tier unit
**D)** The unit of LP share accounting minted per deposit

<details>
<summary>Answer</summary>

**Correct Answer: B**

A tick represents a discrete point on the price curve where liquidity can be positioned and trades can occur. Each tick represents a 0.01% (1 basis point) price change.

**Explanation**:
- Ticks divide the continuous price spectrum into manageable segments
- Formula: `price = 1.0001^tick`
- Concentrated liquidity is placed between tick ranges
- Ticks enable capital efficiency by allowing LPs to provide liquidity at specific price points

**Why other options are wrong**:
- A: TWAP uses observations, not ticks (though tick data feeds into TWAP)
- C: Fee tiers (0.01%, 0.05%, 0.30%, 1.00%) are separate from ticks
- D: LP shares are calculated from liquidity amount, not ticks
</details>

---

### Question 2: What's the formula for calculating the price at a specific tick?

**A)** price = sqrt(i) * 2^96
**B)** price = 2^i
**C)** price = 1.0001^i
**D)** price = 10^i

<details>
<summary>Answer</summary>

**Correct Answer: C**

The formula is: `price = 1.0001^tick`

**Explanation**:
- 1.0001 represents a 0.01% (1 basis point) price change
- Raising to the power of the tick gives the price ratio
- This creates geometric price spacing

**Examples**:
```
Tick 0:     price = 1.0001^0 = 1.0 (1:1 ratio)
Tick 100:   price = 1.0001^100 ≈ 1.01005 (~1% higher)
Tick -100:  price = 1.0001^(-100) ≈ 0.99005 (~1% lower)
Tick 6931:  price = 1.0001^6931 ≈ 2.0 (2:1 ratio)
```

**Why other options are wrong**:
- A: This describes sqrtPriceX96 encoding, not the tick-to-price formula
- B: Would create exponential growth (too rapid)
- D: Would create even more extreme exponential growth
</details>

---

### Question 3: What is the square root price (in Q64.96 format) for a pool at tick 100?

**A)** ~4.12 * 10^54
**B)** ~7.73 * 10^20
**C)** ~7.962 * 10^28

<details>
<summary>Answer</summary>

**Correct Answer: C** (~7.962 * 10^28)

**Calculation**:
```
Step 1: Calculate price from tick
price = 1.0001^100 ≈ 1.01005

Step 2: Take square root
√price = √1.01005 ≈ 1.005012

Step 3: Convert to Q64.96
sqrtPriceX96 = 1.005012 × 2^96
sqrtPriceX96 = 1.005012 × 79,228,162,514,264,337,593,543,950,336
sqrtPriceX96 ≈ 79,625,145,810,786,473,216,385,223,744
sqrtPriceX96 ≈ 7.962 × 10^28
```

**Verification**: Squaring and dividing by 2^192 should give ~1.01005 ✓
</details>

---

### Question 4: How do you convert a decimal number to Q64.96?

**A)** Multiply by 2^96
**B)** Multiply by 10^96
**C)** Raise to the power of tick
**D)** Divide by 2^96

<details>
<summary>Answer</summary>

**Correct Answer: A** (Multiply by 2^96)

**Formula**: `Q64.96_value = decimal_number × 2^96`

**Example**:
```solidity
// Convert 1.5 to Q64.96
uint256 decimal = 1.5;  // Conceptually
uint256 q64_96 = 1.5 * 2**96;
// Result: 118,842,243,771,396,506,690,315,925,504

// Convert back
decimal = q64_96 / 2**96;  // Returns 1.5
```

**Why 2^96?**
- Q64.96 format reserves 96 bits for fractional precision
- Scaling by 2^96 converts decimal to fixed-point integer
- Provides ~29 decimal places of precision

**Why other options are wrong**:
- B: 10^96 would be base-10 scaling (not used in Solidity)
- C: That's for tick-to-price conversion
- D: That converts FROM Q64.96 to decimal (inverse operation)
</details>

---

### Question 5: In a specific pool, the current tick is -23421. What is the relative price of Token 0 to Token 1?

**A)** 1 Token 0 = 10.401 Token 1
**B)** 1 Token 0 = 0.961 Token 1
**C)** 0.0961 Token 0 = 1 Token 1
**D)** 1 Token 0 = 0.0961 Token 1

<details>
<summary>Answer</summary>

**Correct Answer: D** (1 Token 0 = 0.0961 Token 1)

**Calculation**:
```
price = 1.0001^tick
price = 1.0001^(-23421)
price ≈ 0.0961

Interpretation:
1 Token 0 = 0.0961 Token 1

Or equivalently:
1 Token 1 = 10.406 Token 0 (approximately)
```

**Understanding negative ticks**:
- Negative tick → Token 0 is worth LESS than Token 1
- Tick -23421 means the price has moved down by ~90.4%
- The more negative, the cheaper Token 0 relative to Token 1

**Real-world example**:
If Token 0 = ETH and Token 1 = USDC at tick -23421:
- 1 ETH = 96.1 USDC (ETH is worth less)
- Or: 1 USDC = 0.0104 ETH
</details>

---

## Section 2: Q64.96 Mathematics

### Question 6: What happens when you multiply two Q64.96 numbers without adjustment?

**A)** The result is correctly scaled
**B)** The result is scaled by 2^192 (wrong!)
**C)** The result is scaled by 2^96
**D)** Overflow error

<details>
<summary>Answer</summary>

**Correct Answer: B**

When multiplying two Q64.96 numbers, you get:
```
(a × 2^96) × (b × 2^96) = (a × b) × 2^192
```

The result is scaled by 2^192, not 2^96!

**Correct pattern**:
```solidity
