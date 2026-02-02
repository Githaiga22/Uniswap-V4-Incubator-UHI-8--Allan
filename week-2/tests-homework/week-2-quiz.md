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
uint256 result = (a * b) / 2**96;  // Restore correct scale
```

**Why this matters**:
- Forgetting to divide causes massive value inflation
- Critical bug in price/liquidity calculations
- Can drain pools if used in swap logic

**Real bug scenario**:
```solidity
// WRONG
uint160 wrongPrice = price1 * price2;  // Scaled by 2^192!

// CORRECT
uint160 correctPrice = uint160((uint256(price1) * uint256(price2)) / 2**96);
```
</details>

---

### Question 7: What's the maximum price a uint160 sqrtPriceX96 can represent?

**A)** 2^160
**B)** ~3.4 × 10^38
**C)** 2^96
**D)** Unlimited

<details>
<summary>Answer</summary>

**Correct Answer: B** (~3.4 × 10^38)

**Calculation**:
```
Max sqrtPriceX96 = 2^160 - 1

Divide by 2^96 to get √P:
√P_max = (2^160 - 1) / 2^96
√P_max ≈ 2^64 ≈ 1.844 × 10^19

Square to get P:
P_max = (√P_max)^2
P_max ≈ 3.4 × 10^38
```

**Practical range**:
- Min tick: -887,272
- Max tick: 887,272
- Covers price ratios from ~10^-38 to ~10^38

**Why this range?**
- Can represent any realistic token pair price
- From $0.00...01 to $10^38
- Even extreme ratios (SHIB/BTC) fit comfortably
</details>

---

## Section 3: Hook Development

### Question 8: Why must hook addresses encode their permissions?

**A)** For gas optimization
**B)** To prevent unauthorized hooks
**C)** For quick permission validation without storage reads
**D)** It's just a convention

<details>
<summary>Answer</summary>

**Correct Answer: C**

Hook addresses encode permissions in the last 14 bits for **gas-efficient validation**.

**How it works**:
```solidity
// Instead of:
mapping(address => Permissions) public hookPermissions;  // Storage read: 2,100 gas

// V4 does:
uint160 flags = uint160(hookAddress) & 0x3FFF;  // Bitwise AND: <100 gas
bool hasAfterSwap = flags & AFTER_SWAP_FLAG != 0;
```

**Benefits**:
- No storage reads (saves ~2,000 gas per check)
- Permissions immutable (can't be changed post-deployment)
- Protocol validates instantly using address bits

**Trade-off**:
- Must use CREATE2 with salt mining
- Deployment takes longer (finding valid address)
- But saves gas on EVERY pool interaction
</details>

---

### Question 9: What does the _assignPoints pattern improve?

**A)** Gas efficiency
**B)** Code organization and maintainability
**C)** Event emission consistency
**D)** All of the above

<details>
<summary>Answer</summary>

**Correct Answer: D** (All of the above)

The `_assignPoints` helper function provides multiple benefits:

**1. Gas Efficiency**:
```solidity
// Function inlining by compiler
// Single location for optimization
```

**2. Code Organization**:
```solidity
// DRY principle - Don't Repeat Yourself
function _assignPoints(address user, PoolId poolId, uint256 points) internal {
    userPoints[user][poolId] += points;
    emit PointsAwarded(user, poolId, points);
}

// Used in multiple places
function _afterSwap(...) internal override {
    _assignPoints(sender, poolId, POINTS_PER_SWAP);  // Clean!
}
```

**3. Event Consistency**:
```solidity
// Always emits event when assigning points
// Can't forget to emit in one place but not another
```

**4. Maintainability**:
- Change logic once, affects all callsites
- Easier testing (test one function)
- Clearer code intent

**Pattern extends to**:
- `_validateAccess()`
- `_updateMetrics()`
- `_calculateFee()`
</details>

---

### Question 10: Why use events in hooks?

**A)** Required by the protocol
**B)** For debugging only
**C)** Enable off-chain indexing and frontend queries
**D)** Increase gas costs

<details>
<summary>Answer</summary>

**Correct Answer: C**

Events are **critical for scalability** and user experience:

**Problem without events**:
```solidity
// To get user's total points across all pools:
// Must iterate ALL pools on-chain
// Impossible / extremely expensive
```

**Solution with events**:
```solidity
emit PointsAwarded(user, poolId, points);

// Off-chain indexer (The Graph) listens
// Aggregates data efficiently
// Frontend queries via GraphQL
```

**Architecture**:
```
Hook (on-chain)     Indexer (off-chain)     Frontend
     │                     │                     │
     ├─ Emit events ──────→ Index events        │
     │                     │                     │
     │                     ├─ Aggregate data    │
     │                     │                     │
     │                     │←─── Query data ────┤
```

**Gas consideration**:
- Events cost ~375-750 gas per indexed field
- Tiny compared to storage (20,000 gas)
- Worth it for UX scalability

**Why other options wrong**:
- A: Optional, but highly recommended
- B: Events are production tools, not just debug
- D: Events are cheaper than alternatives
</details>

---

## Section 4: Testing & Deployment

### Question 11: What does `vm.deal(address, amount)` do?

**A)** Transfers ETH between addresses
**B)** Sets an address's ETH balance directly (test only)
**C)** Calculates deal price
**D)** Creates a mock ERC20 token

<details>
<summary>Answer</summary>

**Correct Answer: B**

`vm.deal()` is a Foundry **cheat code** that directly sets ETH balance in tests:

```solidity
// Before
assertEq(alice.balance, 0);

// Magic!
vm.deal(alice, 100 ether);

// After
assertEq(alice.balance, 100 ether);
```

**How it works**:
- Foundry's EVM can manipulate state freely
- No transfer, no minting - just sets `balance[address] = amount`
- **Only works in tests**, not on mainnet

**Use cases**:
```solidity
// Give test contracts ETH
vm.deal(address(this), 10 ether);

// Fund multiple users
address[] memory users = [alice, bob, charlie];
for (uint i = 0; i < users.length; i++) {
    vm.deal(users[i], 100 ether);
}
```

**Similar cheat codes**:
- `deal(token, user, amount)` - Set ERC20 balance
- `vm.roll(block)` - Set block number
- `vm.warp(timestamp)` - Set block timestamp
</details>

---

### Question 12: What does `forge test -vvvv` show that `-vv` doesn't?

**A)** Nothing, same output
**B)** Gas reports
**C)** Stack traces and detailed execution paths
**D)** Code coverage

<details>
<summary>Answer</summary>

**Correct Answer: C**

**Verbosity comparison**:
```bash
forge test        # Pass/fail only
forge test -v     # Test names
forge test -vv    # + console.log output
forge test -vvv   # + Stack traces on failure
forge test -vvvv  # + Setup traces & call depth
forge test -vvvvv # + ALL internal calls (very verbose)
```

**Example `-vvvv` output**:
```
[FAIL. Reason: revert: Insufficient balance]
    ├─ [0] VM::prank(alice)
    ├─ [2000] PointsHook::swap()
    │   ├─ [500] PoolManager::lock()
    │   │   └─ ← revert: Insufficient balance
    │   └─ ← revert
    └─ ← revert

Traces:
  [2000] PointsHook::swap()
    ├─ caller: alice (0x123...)
    ├─ gas: 50000
    └─ ERROR: Insufficient balance at line 42
```

**When to use each**:
- `-vv`: Development (see your logs)
- `-vvv`: Failed test (where did it revert?)
- `-vvvv`: Complex debugging (full execution trace)
- `-vvvvv`: Rarely (analyzing internal behavior)
</details>

---

### Question 13: Why use `vm.rollFork()` in tests?

**A)** To restart the test
**B)** To time travel to specific block in forked tests
**C)** To roll back transactions
**D)** To switch networks

<details>
<summary>Answer</summary>

**Correct Answer: B**

`vm.rollFork()` moves to a different block in forked mainnet tests:

```solidity
function testForkTimeTravel() public {
    // Fork mainnet
    vm.createSelectFork(MAINNET_RPC);

    // Current state at block 19,000,000
    uint256 currentBlock = block.number;
    console.log("Current:", currentBlock);  // 19,000,000

    // Perform action
    swap(poolKey, 1 ether);

    // Fast forward 100 blocks
    vm.rollFork(currentBlock + 100);
    console.log("After roll:", block.number);  // 19,000,100

    // State from 100 blocks later is now loaded
    // Can test how hook behaves over time
}
```

**Use cases**:
- Test time-dependent logic (vesting, expiry)
- Simulate market conditions at different blocks
- Test protocol upgrades
- Verify historical behavior

**Important**:
- Only works with forked tests
- Rolling forward: `vm.rollFork(block.number + n)`
- Rolling backward: `vm.rollFork(block.number - n)`
- Can jump to any block in chain history
</details>

---

### Question 14: What's the purpose of `forge coverage`?

**A)** Generate insurance coverage
**B)** Measure test coverage (lines/branches/functions tested)
**C)** Deploy contracts with coverage
**D)** Optimize gas coverage

<details>
<summary>Answer</summary>

**Correct Answer: B**

`forge coverage` analyzes which parts of your code are tested:

```bash
$ forge coverage --report summary

| File            | % Lines | % Statements | % Branches | % Funcs |
|-----------------|---------|--------------|------------|---------|
| PointsHook.sol  | 92.31%  | 93.75%       | 75.00%     | 100.00% |
| MyFirstHook.sol | 100.00% | 100.00%      | 100.00%    | 100.00% |
```

**What it measures**:
- **Lines**: Individual lines executed
- **Statements**: Solidity statements run
- **Branches**: Both paths of if/else tested
- **Functions**: All functions called

**Target**: >90% coverage for production code

**Finding gaps**:
```bash
forge coverage --report debug

# Shows:
PointsHook.sol
  Line 42: NOT COVERED (edge case: zero amount)
  Line 67: NOT COVERED (revert path)
```

**Best practice**:
```bash
# Before deployment
forge coverage --report summary

# If < 90%, write more tests
# Focus on uncovered branches (error paths)
```
</details>

---
