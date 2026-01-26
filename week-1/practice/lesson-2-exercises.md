# Lesson 2: Ticks and Q64.96 - Practical Exercises

**Date**: January 22, 2026 (Week 1 - Day 2)
**Focus**: Hands-on practice with ticks, Q64.96 conversions, and price calculations

---

## Exercise Set 1: Tick Conversions (Beginner)

### Exercise 1.1: Price to Tick
**Task**: Convert these prices to their corresponding tick values.

**Given Prices**:
a) 1.0
b) 1.10
c) 0.90
d) 2.0

**Formula**: tick = log(price) / log(1.0001)

<details>
<summary>Solutions</summary>

**a) Price = 1.0**
```
tick = log(1.0) / log(1.0001)
tick = 0 / 0.000043429
tick = 0
```

**b) Price = 1.10**
```
tick = log(1.10) / log(1.0001)
tick = 0.095310 / 0.000043429
tick ≈ 2,195
```

**c) Price = 0.90**
```
tick = log(0.90) / log(1.0001)
tick = -0.105361 / 0.000043429
tick ≈ -2,427
```

**d) Price = 2.0**
```
tick = log(2.0) / log(1.0001)
tick = 0.693147 / 0.000043429
tick ≈ 6,931
```
</details>

---

### Exercise 1.2: Tick to Price
**Task**: Calculate the price for these tick values.

**Given Ticks**:
a) 1000
b) -500
c) 5000
d) -10000

**Formula**: price = 1.0001^tick

<details>
<summary>Solutions</summary>

**a) Tick = 1000**
```
price = 1.0001^1000
price ≈ 1.1052
(10.52% increase)
```

**b) Tick = -500**
```
price = 1.0001^(-500)
price ≈ 0.9512
(4.88% decrease)
```

**c) Tick = 5000**
```
price = 1.0001^5000
price ≈ 1.6487
(64.87% increase)
```

**d) Tick = -10000**
```
price = 1.0001^(-10000)
price ≈ 0.3679
(63.21% decrease)
```
</details>

---

### Exercise 1.3: Tick Spacing Adjustment
**Task**: You want to provide liquidity at these ticks, but need to adjust for tick spacing. Round to the nearest valid tick.

**Scenarios**:
a) Desired tick: 1234, Pool fee: 0.30% (spacing = 60)
b) Desired tick: -577, Pool fee: 0.05% (spacing = 10)
c) Desired tick: 8888, Pool fee: 1.00% (spacing = 200)

<details>
<summary>Solutions</summary>

**a) Tick 1234 with spacing 60**
```
1234 ÷ 60 = 20.566...

Nearest multiples:
- 20 × 60 = 1200
- 21 × 60 = 1260

Closer to 1200
Answer: Tick 1200 ✅
```

**b) Tick -577 with spacing 10**
```
-577 ÷ 10 = -57.7

Nearest multiples:
- -58 × 10 = -580
- -57 × 10 = -570

Closer to -580
Answer: Tick -580 ✅
```

**c) Tick 8888 with spacing 200**
```
8888 ÷ 200 = 44.44

Nearest multiples:
- 44 × 200 = 8800
- 45 × 200 = 9000

Closer to 8800
Answer: Tick 8800 ✅
```
</details>

---

## Exercise Set 2: Q64.96 Conversions (Intermediate)

### Exercise 2.1: Decimal to Q64.96
**Task**: Convert these decimal values to Q64.96 format.

**Given**: 2^96 = 79,228,162,514,264,337,593,543,950,336

**Values to convert**:
a) 1.0
b) 0.5
c) 10.0
d) 0.001

<details>
<summary>Solutions</summary>

**a) 1.0 to Q64.96**
```
Q64.96 = 1.0 × 2^96
Q64.96 = 1.0 × 79,228,162,514,264,337,593,543,950,336
Q64.96 = 79,228,162,514,264,337,593,543,950,336
```

**b) 0.5 to Q64.96**
```
Q64.96 = 0.5 × 2^96
Q64.96 = 0.5 × 79,228,162,514,264,337,593,543,950,336
Q64.96 = 39,614,081,257,132,168,796,771,975,168
```

**c) 10.0 to Q64.96**
```
Q64.96 = 10.0 × 2^96
Q64.96 = 10.0 × 79,228,162,514,264,337,593,543,950,336
Q64.96 = 792,281,625,142,643,375,935,439,503,360
```

**d) 0.001 to Q64.96**
```
Q64.96 = 0.001 × 2^96
Q64.96 = 0.001 × 79,228,162,514,264,337,593,543,950,336
Q64.96 = 79,228,162,514,264,337,593,543,950
```
</details>

---

### Exercise 2.2: Q64.96 to Decimal
**Task**: Convert these Q64.96 values back to decimal.

**Q64.96 Values**:
a) 158,456,325,028,528,675,187,087,900,672
b) 39,614,081,257,132,168,796,771,975,168
c) 7,922,816,251,426,433,759,354,395,033,600

<details>
<summary>Solutions</summary>

**a) 158,456,325,028,528,675,187,087,900,672**
```
decimal = Q64.96 ÷ 2^96
decimal = 158,456,325,028,528,675,187,087,900,672 ÷ 79,228,162,514,264,337,593,543,950,336
decimal = 2.0
```

**b) 39,614,081,257,132,168,796,771,975,168**
```
decimal = Q64.96 ÷ 2^96
decimal = 39,614,081,257,132,168,796,771,975,168 ÷ 79,228,162,514,264,337,593,543,950,336
decimal = 0.5
```

**c) 7,922,816,251,426,433,759,354,395,033,600**
```
decimal = Q64.96 ÷ 2^96
decimal = 7,922,816,251,426,433,759,354,395,033,600 ÷ 79,228,162,514,264,337,593,543,950,336
decimal = 100.0
```
</details>

---

### Exercise 2.3: Q64.96 Arithmetic
**Task**: Perform these operations on Q64.96 numbers.

Let:
- a = 4 (in Q64.96 = 316,912,650,057,057,350,374,175,801,344)
- b = 2 (in Q64.96 = 158,456,325,028,528,675,187,087,900,672)

**Operations**:
a) a + b
b) a × b (remember to adjust scale!)
c) a ÷ b (remember to adjust scale!)

<details>
<summary>Solutions</summary>

**a) Addition: a + b**
```
Addition is straightforward with Q64.96

result = 316,912,650,057,057,350,374,175,801,344 + 158,456,325,028,528,675,187,087,900,672
result = 475,368,975,085,586,025,561,263,702,016

Convert back:
475,368,975,085,586,025,561,263,702,016 ÷ 2^96 = 6.0 ✅
```

**b) Multiplication: a × b**
```
MUST divide by 2^96 after multiplying!

result = (a × b) ÷ 2^96
result = (316,912,650,057,057,350,374,175,801,344 × 158,456,325,028,528,675,187,087,900,672) ÷ 2^96

Simplified calculation:
result = (4 × 2^96) × (2 × 2^96) ÷ 2^96
result = 8 × 2^96
result = 633,825,300,114,114,700,748,351,602,688

Convert back:
633,825,300,114,114,700,748,351,602,688 ÷ 2^96 = 8.0 ✅

❌ WRONG: Just multiplying gives 2^192 scale!
```

**c) Division: a ÷ b**
```
MUST multiply by 2^96 before dividing!

result = (a × 2^96) ÷ b
result = (316,912,650,057,057,350,374,175,801,344 × 2^96) ÷ 158,456,325,028,528,675,187,087,900,672

Simplified calculation:
result = (4 × 2^96 × 2^96) ÷ (2 × 2^96)
result = 2 × 2^96
result = 158,456,325,028,528,675,187,087,900,672

Convert back:
158,456,325,028,528,675,187,087,900,672 ÷ 2^96 = 2.0 ✅

❌ WRONG: Just dividing loses precision!
```
</details>

---

## Exercise Set 3: sqrtPriceX96 (Advanced)

### Exercise 3.1: Price to sqrtPriceX96
**Task**: Convert these prices to sqrtPriceX96 format.

**Prices**:
a) $1000
b) $2500
c) $0.50

<details>
<summary>Solutions</summary>

**a) Price = $1000**
```
Step 1: Take square root
√1000 ≈ 31.6228

Step 2: Convert to Q64.96
sqrtPriceX96 = 31.6228 × 2^96
sqrtPriceX96 = 31.6228 × 79,228,162,514,264,337,593,543,950,336
sqrtPriceX96 = 2,505,414,483,750,824,843,905,891,325,952
```

**b) Price = $2500**
```
Step 1: Take square root
√2500 = 50.0

Step 2: Convert to Q64.96
sqrtPriceX96 = 50.0 × 2^96
sqrtPriceX96 = 50.0 × 79,228,162,514,264,337,593,543,950,336
sqrtPriceX96 = 3,961,408,125,713,216,879,677,197,516,800
```

**c) Price = $0.50**
```
Step 1: Take square root
√0.50 ≈ 0.7071

Step 2: Convert to Q64.96
sqrtPriceX96 = 0.7071 × 2^96
sqrtPriceX96 = 0.7071 × 79,228,162,514,264,337,593,543,950,336
sqrtPriceX96 = 56,022,770,974,786,139,918,731,938,227
```
</details>

---

### Exercise 3.2: sqrtPriceX96 to Price
**Task**: Convert these sqrtPriceX96 values back to regular prices.

**sqrtPriceX96 Values**:
a) 3,961,408,125,713,216,879,677,197,516,800
b) 1,252,707,241,875,412,421,952,945,662,976

<details>
<summary>Solutions</summary>

**a) sqrtPriceX96 = 3,961,408,125,713,216,879,677,197,516,800**
```
Step 1: Convert from Q64.96
√P = 3,961,408,125,713,216,879,677,197,516,800 ÷ 2^96
√P = 3,961,408,125,713,216,879,677,197,516,800 ÷ 79,228,162,514,264,337,593,543,950,336
√P = 50.0

Step 2: Square to get price
P = (50.0)^2
P = 2500

Answer: $2500 ✅
```

**b) sqrtPriceX96 = 1,252,707,241,875,412,421,952,945,662,976**
```
Step 1: Convert from Q64.96
√P = 1,252,707,241,875,412,421,952,945,662,976 ÷ 2^96
√P ≈ 15.8114

Step 2: Square to get price
P = (15.8114)^2
P ≈ 250.0

Answer: $250 ✅
```
</details>

---

### Exercise 3.3: Slippage Limits
**Task**: Calculate sqrtPriceLimitX96 for these swap scenarios.

**Scenario A**:
- Selling ETH for USDC
- Expected price: $2000
- Max slippage: 2%

**Scenario B**:
- Buying ETH with USDC
- Expected price: $1800
- Max slippage: 1.5%

<details>
<summary>Solutions</summary>

**Scenario A: Selling ETH (price should not fall below limit)**
```
Expected: $2000
Slippage: 2%

Minimum acceptable price:
P_min = 2000 × (1 - 0.02)
P_min = 2000 × 0.98
P_min = 1960

Convert to sqrtPriceX96:
√1960 ≈ 44.2719

sqrtPriceLimitX96 = 44.2719 × 2^96
sqrtPriceLimitX96 = 3,508,112,621,881,767,893,456,879,104,000

Swap will REVERT if price drops below $1960 ✅
```

**Scenario B: Buying ETH (price should not rise above limit)**
```
Expected: $1800
Slippage: 1.5%

Maximum acceptable price:
P_max = 1800 × (1 + 0.015)
P_max = 1800 × 1.015
P_max = 1827

Convert to sqrtPriceX96:
√1827 ≈ 42.7435

sqrtPriceLimitX96 = 42.7435 × 2^96
sqrtPriceLimitX96 = 3,387,243,287,546,892,154,678,012,928,000

Swap will REVERT if price rises above $1827 ✅
```
</details>

---

## Exercise Set 4: Liquidity Positions (Advanced)

### Exercise 4.1: Calculate Token Amounts
**Task**: You have $10,000 to provide liquidity for ETH/USDC.

**Given**:
- Current ETH price: $2000
- Your range: $1800 - $2200
- Total capital: $10,000

Calculate how much ETH and USDC you need.

<details>
<summary>Solution</summary>

**Step 1: Convert prices to ticks**
```
Current: $2000 → tick ≈ 6,931
Lower: $1800 → tick ≈ 5,877
Upper: $2200 → tick ≈ 7,875
```

**Step 2: Calculate square roots**
```
√P = √2000 ≈ 44.721
√P_a = √1800 ≈ 42.426
√P_b = √2200 ≈ 46.904
```

**Step 3: Determine capital split**
At current price in range, you need both tokens.

The ratio depends on the formula:
```
Ratio = (√P - √P_a) / (√P_b - √P_a)

Ratio = (44.721 - 42.426) / (46.904 - 42.426)
Ratio = 2.295 / 4.478
Ratio ≈ 0.5125 (51.25%)

This means:
USDC needed: 51.25% of $10,000 = $5,125
ETH value: 48.75% of $10,000 = $4,875
```

**Step 4: Convert to token amounts**
```
USDC: $5,125
ETH: $4,875 ÷ $2000 per ETH = 2.4375 ETH

Final amounts:
- 2.4375 ETH
- 5,125 USDC
- Total value: $10,000 ✅
```

**Note**: Exact amounts vary based on current pool liquidity and precise tick calculations. Use Uniswap's SDK for production calculations.
</details>

---

### Exercise 4.2: Position Status Check
**Task**: Analyze these liquidity positions.

**Position A**:
- Range: Tick -1000 to Tick 1000
- Current tick: 500

**Position B**:
- Range: Tick 5000 to Tick 8000
- Current tick: 9000

**Position C**:
- Range: Tick -500 to Tick 2000
- Current tick: -600

For each, determine:
1. Is it in range?
2. What's the token composition?
3. Is it earning fees?

<details>
<summary>Solutions</summary>

**Position A**: Tick -1000 to 1000, Current: 500
```
1. In range? YES ✅
   (500 is between -1000 and 1000)

2. Token composition: MIX of both tokens
   - Approximately 50/50 since current tick is near middle

3. Earning fees? YES ✅
   - Position is active and facilitating swaps
```

**Position B**: Tick 5000 to 8000, Current: 9000
```
1. In range? NO ❌
   (9000 is ABOVE 8000)

2. Token composition: 100% Token0
   - Price moved above range
   - All capital converted to Token0 (e.g., ETH)

3. Earning fees? NO ❌
   - Position is inactive
   - Need to rebalance or wait for price to drop
```

**Position C**: Tick -500 to 2000, Current: -600
```
1. In range? NO ❌
   (-600 is BELOW -500)

2. Token composition: 100% Token1
   - Price moved below range
   - All capital converted to Token1 (e.g., USDC)

3. Earning fees? NO ❌
   - Position is inactive
   - Need to rebalance or wait for price to rise
```
</details>

---

## Exercise Set 5: Coding Challenges (Expert)

### Exercise 5.1: Implement Tick Math
**Task**: Write a Solidity function to convert price to tick.

**Requirements**:
- Input: uint256 price (as regular number, not Q64.96)
- Output: int24 tick
- Use approximation for log calculation

<details>
<summary>Solution</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TickMathHelper {
    /// @notice Calculates tick from price (approximate)
