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

