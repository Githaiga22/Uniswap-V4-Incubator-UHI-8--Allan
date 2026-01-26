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
**Write Solidity code to check if current price is within a liquidity position's range.**

<details>
<summary>Answer</summary>

```solidity
function isPriceInRange(
    uint160 currentSqrtPriceX96,
    int24 tickLower,
    int24 tickUpper
) internal pure returns (bool) {
    // Convert ticks to sqrtPriceX96 values
    uint160 sqrtPriceLower = getSqrtRatioAtTick(tickLower);
    uint160 sqrtPriceUpper = getSqrtRatioAtTick(tickUpper);

    // Check if current price is between bounds
    return currentSqrtPriceX96 >= sqrtPriceLower &&
           currentSqrtPriceX96 <= sqrtPriceUpper;
}
```

**Explanation**:
1. Convert tick boundaries to sqrtPriceX96 values using library function
2. Compare current price against both bounds
3. Returns true if in range, false if outside

**Usage**:
```solidity
bool inRange = isPriceInRange(
    pool.slot0().sqrtPriceX96,
    position.tickLower,
    position.tickUpper
);

if (inRange) {
    // Position is earning fees
} else {
    // Position is inactive
}
```
</details>

---

## Section 4: Advanced Understanding (Technical)

### Question 13
**Why does Uniswap use square root of price instead of price directly?**

<details>
<summary>Answer</summary>

**Mathematical Efficiency**:

Using price directly requires complex formulas:
```
Computing liquidity:
L = Δx × Δy
(Requires multiplication, division, AND square roots)
```

Using square root of price simplifies:
```
With √P:
L = Δx × √P
OR
L = Δy / √P
(Much simpler - just multiplication or division!)
```

**Gas Savings**:
- Fewer operations = lower gas costs
- Square roots already calculated = reusable
- Precision maintained throughout calculations

**Real Impact**:
A typical swap might save 10-30% gas by using √P instead of P directly.

**The Math**: Because of the constant product formula (x × y = k), when you manipulate it algebraically, square roots naturally appear. Rather than compute them repeatedly, Uniswap stores √P directly.
</details>

---

### Question 14
**Calculate the liquidity needed if you have 2 ETH at current price $2000 and want to provide liquidity from $1500 to $2500.**

<details>
<summary>Answer</summary>

**Given**:
- Δx (ETH amount) = 2
- P (current price) = 2000
- P_a (lower bound) = 1500
- P_b (upper bound) = 2500

**Step 1**: Convert to square roots
```
√P = √2000 ≈ 44.721
√P_a = √1500 ≈ 38.730
√P_b = √2500 = 50.000
```

**Step 2**: Calculate liquidity (L)
```
Formula: L = Δx × √P_b × √P / (√P_b - √P)

L = 2 × 50.000 × 44.721 / (50.000 - 44.721)
L = 2 × 50.000 × 44.721 / 5.279
L = 4,472.1 / 5.279
L ≈ 847.1
```

**Step 3**: Calculate USDC needed (Δy)
```
Formula: Δy = L × (√P - √P_a)

Δy = 847.1 × (44.721 - 38.730)
Δy = 847.1 × 5.991
Δy ≈ 5,076 USDC
```

**Answer**: You need approximately **5,076 USDC** to pair with your 2 ETH for this range.
</details>

---

### Question 15
**What's the maximum and minimum price a uint160 sqrtPriceX96 can represent?**

<details>
<summary>Answer</summary>

**Maximum sqrtPriceX96**:
```
Max uint160 = 2^160 - 1
           = 1,461,501,637,330,902,918,203,684,832,716,283,019,655,932,542,975

Divide by 2^96 to get √P_max:
√P_max ≈ 18,446,744,073,709,551,615

Square to get P_max:
P_max = (√P_max)^2
P_max ≈ 3.4 × 10^38
```

**Minimum sqrtPriceX96**:
```
Min practical value (from TickMath):
sqrtPriceX96_min = 4,295,128,739

This represents:
√P_min = 4,295,128,739 ÷ 2^96 ≈ 0.0000000542
P_min ≈ 0.00000000000000294

Or roughly 1.0001^(-887,272)
```

**Practical Range**:
- Min tick: -887,272
- Max tick: 887,272
- This covers price ratios from ~10^-38 to ~10^38

**Why this matters**: This range can handle essentially any realistic token price ratio, from fractions of a penny to millions of dollars.
</details>

---

## Section 5: Hook Development Context (Advanced)

### Question 16
**You're building a limit order hook. How would you use ticks and sqrtPriceX96 to implement it?**

<details>
<summary>Answer</summary>

**Architecture**:

```solidity
contract LimitOrderHook is BaseHook {
    struct LimitOrder {
        int24 targetTick;           // Tick where order executes
        uint160 targetSqrtPriceX96; // Corresponding price
        uint256 amountIn;           // Input token amount
        bool zeroForOne;            // Swap direction
    }

    mapping(bytes32 => LimitOrder) public orders;

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        // Get current pool price
        (uint160 currentSqrtPriceX96,,) =
            poolManager.getSlot0(key.toId());

        // Check limit orders
        bytes32[] memory orderIds = getActiveOrders(key.toId());

        for (uint i = 0; i < orderIds.length; i++) {
            LimitOrder memory order = orders[orderIds[i]];

            // Check if target price reached
            bool triggered = order.zeroForOne
                ? currentSqrtPriceX96 <= order.targetSqrtPriceX96
                : currentSqrtPriceX96 >= order.targetSqrtPriceX96;

            if (triggered) {
                executeOrder(orderIds[i], key);
            }
        }

        return BaseHook.afterSwap.selector;
    }
}
```

**Key Concepts**:
1. Store target tick/price for each order
2. Monitor price in afterSwap hook
3. Execute order when price crosses target
4. Use sqrtPriceX96 for accurate price comparisons
</details>

---

### Question 17
**How would you calculate price impact using sqrtPriceX96 values?**

<details>
<summary>Answer</summary>

```solidity
function calculatePriceImpact(
    uint160 sqrtPriceBefore,
    uint160 sqrtPriceAfter
) internal pure returns (uint256 impactBps) {
