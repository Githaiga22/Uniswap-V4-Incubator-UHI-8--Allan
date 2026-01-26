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
    /// @param price The price as a regular uint256
    /// @return tick The corresponding tick value
    function getTickFromPrice(uint256 price)
        internal
        pure
        returns (int24 tick)
    {
        require(price > 0, "Price must be positive");

        // Convert price to Q64.96
        uint160 sqrtPriceX96 = uint160(
            sqrt(price) * (2 ** 96)
        );

        // Use Uniswap's TickMath library for precise conversion
        tick = getTickAtSqrtRatio(sqrtPriceX96);
    }

    /// @notice Calculate square root (Babylonian method)
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        uint256 y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }

        return y;
    }

    /// @notice Get tick from sqrtPriceX96 (simplified)
    /// @dev In production, use Uniswap's TickMath.getTickAtSqrtRatio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96)
        internal
        pure
        returns (int24 tick)
    {
        // Simplified approximation
        // Real implementation uses binary search + lookup table

        uint256 ratio = uint256(sqrtPriceX96);

        // Approximate using log base 1.0001
        // tick ≈ log(ratio) / log(1.0001)

        // This is a simplified version
        // Use Uniswap's library for production!
        require(ratio >= 4295128739 && ratio <= 1461446703485210103287273052203988822378723970342, "Invalid ratio");

        // Binary search implementation would go here
        // For this exercise, acknowledge complexity
        // and recommend using Uniswap's battle-tested library

        revert("Use TickMath library from Uniswap v4-core");
    }
}
```

**Learning Point**: Tick math is complex! In production, always use Uniswap's audited libraries:
```solidity
import {TickMath} from "v4-core/libraries/TickMath.sol";

int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
```
</details>

---

### Exercise 5.2: Build a Price Monitor Hook
**Task**: Create a hook that logs significant price changes.

**Requirements**:
- Triggers on price change > 1% (100 ticks)
- Emits event with old and new prices
- Stores price history

<details>
<summary>Solution</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";

contract PriceMonitorHook is BaseHook {
    // Track last recorded price for each pool
    mapping(bytes32 => uint160) public lastSqrtPriceX96;

    // Price change threshold (100 ticks ≈ 1%)
    uint160 public constant PRICE_CHANGE_THRESHOLD = 100;

    event SignificantPriceChange(
        bytes32 indexed poolId,
        uint160 oldSqrtPriceX96,
        uint160 newSqrtPriceX96,
        int24 oldTick,
        int24 newTick,
        uint256 changePercent
    );

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        int24
    ) external override returns (bytes4) {
        // Store initial price
        bytes32 poolId = keccak256(abi.encode(key));
        lastSqrtPriceX96[poolId] = sqrtPriceX96;

        return BaseHook.afterInitialize.selector;
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4) {
        bytes32 poolId = keccak256(abi.encode(key));

        // Get current price
        (uint160 currentSqrtPriceX96, int24 currentTick,) =
            poolManager.getSlot0(poolId);

        uint160 oldSqrtPriceX96 = lastSqrtPriceX96[poolId];

        // Calculate price change
        uint160 priceChange = currentSqrtPriceX96 > oldSqrtPriceX96
            ? currentSqrtPriceX96 - oldSqrtPriceX96
            : oldSqrtPriceX96 - currentSqrtPriceX96;

        // Check if change exceeds threshold
        uint256 changePercent = (uint256(priceChange) * 10000) /
                                uint256(oldSqrtPriceX96);

        if (changePercent >= 100) {  // 1% = 100 basis points
            // Get old tick (approximate)
            int24 oldTick = getTickFromSqrtPrice(oldSqrtPriceX96);

            emit SignificantPriceChange(
                poolId,
                oldSqrtPriceX96,
                currentSqrtPriceX96,
                oldTick,
                currentTick,
                changePercent
            );

            // Update stored price
            lastSqrtPriceX96[poolId] = currentSqrtPriceX96;
        }

        return BaseHook.afterSwap.selector;
    }

    function getTickFromSqrtPrice(uint160 sqrtPriceX96)
        internal
        pure
        returns (int24)
    {
        // Simplified - use TickMath library in production
        return 0; // Placeholder
    }
}
```

**Usage**:
```solidity
// Deploy hook
PriceMonitorHook monitor = new PriceMonitorHook(poolManager);

// Listen for events
monitor.SignificantPriceChange.on("event", (event) => {
    console.log(`Price changed by ${event.changePercent / 100}%`);
});
```
</details>

---

### Exercise 5.3: Dynamic Range Adjuster
**Task**: Write logic to calculate optimal tick range based on volatility.

**Concept**:
- High volatility → wider range
- Low volatility → tighter range

<details>
<summary>Solution</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library RangeOptimizer {
    struct VolatilityData {
        uint256[] priceHistory;  // Last N prices
        uint256 windowSize;      // Number of data points
    }

    /// @notice Calculate optimal tick range based on volatility
    /// @param currentTick The current pool tick
    /// @param volatilityData Historical price data
    /// @return tickLower Lower bound of optimal range
    /// @return tickUpper Upper bound of optimal range
    function calculateOptimalRange(
        int24 currentTick,
        VolatilityData memory volatilityData
    ) internal pure returns (int24 tickLower, int24 tickUpper) {
        // Calculate standard deviation of prices
        uint256 stdDev = calculateStandardDeviation(
            volatilityData.priceHistory
        );

        // Determine range width based on volatility
        int24 rangeWidth;

        if (stdDev < 100) {
            // Low volatility: tight range (±5%)
            rangeWidth = 500;  // ~5%
        } else if (stdDev < 500) {
            // Medium volatility: moderate range (±10%)
            rangeWidth = 1000;  // ~10%
        } else {
            // High volatility: wide range (±20%)
            rangeWidth = 2000;  // ~20%
        }

        // Center range around current tick
        tickLower = currentTick - rangeWidth;
        tickUpper = currentTick + rangeWidth;

        // Adjust for tick spacing (example: spacing = 60)
        tickLower = (tickLower / 60) * 60;
        tickUpper = (tickUpper / 60) * 60;

        return (tickLower, tickUpper);
    }

    /// @notice Calculate standard deviation of prices
    function calculateStandardDeviation(uint256[] memory prices)
        internal
        pure
        returns (uint256)
    {
        require(prices.length > 0, "No price data");

        // Calculate mean
        uint256 sum = 0;
        for (uint i = 0; i < prices.length; i++) {
            sum += prices[i];
        }
        uint256 mean = sum / prices.length;

        // Calculate variance
        uint256 varianceSum = 0;
        for (uint i = 0; i < prices.length; i++) {
            uint256 diff = prices[i] > mean
                ? prices[i] - mean
                : mean - prices[i];
            varianceSum += diff * diff;
        }
        uint256 variance = varianceSum / prices.length;

        // Return square root of variance (standard deviation)
        return sqrt(variance);
    }

    /// @notice Calculate square root (Babylonian method)
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
```

**Example Usage**:
```solidity
// Track price history
uint256[] memory priceHistory = [1000, 1005, 998, 1002, 1010];

VolatilityData memory volData = VolatilityData({
    priceHistory: priceHistory,
    windowSize: 5
});

// Calculate optimal range
(int24 tickLower, int24 tickUpper) =
    RangeOptimizer.calculateOptimalRange(6931, volData);

// tickLower ≈ 6431 (~$940)
// tickUpper ≈ 7431 (~$1060)
// Range: ±~6% based on low volatility
```
</details>

---

## Challenge Project: Build a Position Manager

**Goal**: Create a complete system that manages LP positions automatically.

**Requirements**:
1. Monitor pool prices every block
2. Calculate if position is in/out of range
3. Rebalance when out of range
4. Optimize new ranges based on volatility
5. Emit detailed events for tracking

**Deliverables**:
- Smart contract implementation
- Test suite with edge cases
- Gas optimization analysis
- Documentation

**Hints**:
- Use afterSwap hook for monitoring
- Implement range calculations from Exercise 5.3
- Handle tick spacing correctly
- Consider gas costs of rebalancing
- Test with multiple pool fee tiers

**Bonus Points**:
- Add slippage protection
- Implement emergency pause
- Create UI for visualization
- Deploy to testnet and verify

---

## Practice Tips

1. **Start Simple**: Master tick conversions before Q64.96 math
2. **Use Calculator**: Python/JavaScript for verifying calculations
3. **Visualize**: Draw tick ranges to understand positions
4. **Read Code**: Study Uniswap's TickMath library
5. **Test Edge Cases**: Zero ticks, negative ticks, max values
6. **Gas Awareness**: Some operations are expensive on-chain

---

## Additional Resources

**Calculators & Tools**:
- Uniswap V3/V4 Position Calculator: https://uniswap.org/calculator
- Tick Math Playground: Build your own!
- RareSkills sqrtPriceX96 tool: https://rareskills.io/post/uniswap-v3-sqrtpricex96

**Practice Codebases**:
- v4-core TickMath.sol: Study the source
- v4-periphery examples: Real-world usage
- Hook examples repository: See patterns

---

**Previous**: [Lesson 1 Exercises](./lesson-1-exercises.md)
**Next**: Week 2 practice materials
