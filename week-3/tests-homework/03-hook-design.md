# Hook Design

**Assignment**: UHI Custom Pricing Curve Hook Quest
**Student**: Allan Robinson
**Date**: February 3, 2026

---

## Problem Statement

### The Token Launchpad Dilemma

Traditional Uniswap pools have a fundamental misalignment of incentives for token launchpads:

```
ETH/TOKEN Pool (Traditional):

Buy Swaps (ETH → TOKEN):
├─ Users buy TOKEN with ETH
├─ Pool accumulates ETH
├─ LPs earn fees in TOKEN ❌
└─ Problem: LPs accumulate TOKEN they must sell

Sell Swaps (TOKEN → ETH):
├─ Users sell TOKEN for ETH
├─ Pool loses ETH
├─ LPs earn fees in ETH ✅
└─ But: Sell pressure from both swaps and LP fee realization

Result:
├─ LPs hold fees in BOTH tokens
├─ To realize profit → Must sell TOKEN
├─ Creates constant downward price pressure
└─ Hurts all TOKEN holders
```

### Why This Matters

**For Token Launchpads:**
- Token holders want price appreciation
- LPs want to realize profits
- These goals are in conflict when LPs must sell token

**Current Problems:**
1. **Misaligned Incentives**: LPs profit by selling, holders want no selling
2. **Price Pressure**: Constant sell pressure from fee realization
3. **Poor Optics**: Community perceives "LPs dumping on holders"
4. **Reduced Trust**: Damages community relationships
5. **Unsustainable**: Long-term downward price spiral

### Real-World Example

Consider a new token launch with $100K liquidity pool:

```
Day 1: Launch with 50 ETH + 1M TOKEN
├─ Trading volume: $50K
├─ LP fees (0.3%): $150
├─ Split: $75 in ETH, $75 in TOKEN

Day 7: After active trading week
├─ Cumulative fees: $1,050
├─ LPs hold: $525 ETH + $525 TOKEN
├─ To realize profit → Must sell $525 of TOKEN
├─ At $1M market cap = 0.05% sell pressure
├─ Seems small...

Day 30: After one month
├─ Cumulative fees: $4,500
├─ LPs hold: $2,250 ETH + $2,250 TOKEN
├─ To realize profit → Must sell $2,250 of TOKEN
├─ At $1M market cap = 0.225% sell pressure
├─ Getting significant...

Day 90: After three months
├─ Cumulative fees: $13,500
├─ LPs hold: $6,750 ETH + $6,750 TOKEN
├─ To realize profit → Must sell $6,750 of TOKEN
├─ At $1M market cap = 0.675% sell pressure
├─ Major downward pressure!
```

**The Death Spiral:**
1. LPs accumulate TOKEN fees
2. LPs sell TOKEN to realize profit
3. Selling pushes price down
4. Lower price = more TOKEN in fees (same $ value)
5. Even more selling pressure needed
6. Repeat...

---

## Solution: Internal Swap Pool Hook

### Design Goals

**Primary Goal**: Route all LP fees to ETH only

**Secondary Goals**:
1. No price impact from fee conversion
2. Fair pricing for internal swaps
3. Gas efficient implementation
4. Trustless and transparent
5. Composable with existing tools

### High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                  InternalSwapPool Hook              │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Component 1: Internal Orderbook                   │
│  ├─ Maintains TOKEN reserves from fees             │
│  ├─ Fills TOKEN→ETH swaps from reserves            │
│  └─ Converts TOKEN fees → ETH fees                 │
│                                                     │
│  Component 2: Fee Collection                        │
│  ├─ Captures 1% of all swap outputs                │
│  ├─ Stores TOKEN fees for future conversion        │
│  └─ Stores ETH fees for distribution                │
│                                                     │
│  Component 3: Fee Distribution                      │
│  ├─ Accumulates ETH fees to threshold              │
│  ├─ Distributes via donate() to LPs                │
│  └─ LPs receive ONLY ETH (never TOKEN)             │
│                                                     │
└─────────────────────────────────────────────────────┘
         ↓                           ↓
    ┌────────┐                 ┌──────────┐
    │ AMM    │                 │ LPs Get  │
    │ Swap   │                 │ ETH Fees │
    └────────┘                 └──────────┘
```

### How It Works

#### Scenario 1: Buy Swap (ETH → TOKEN)

```
User wants to buy TOKEN with 1 ETH:

Step 1: beforeSwap
├─ Hook checks: No internal action needed for buy swaps
└─ Returns: Zero delta (let AMM handle it)

Step 2: AMM Swap
├─ Uniswap AMM executes normally
├─ User: Gives 1 ETH
├─ User: Receives ~100 TOKEN (example)
└─ Pool: Price adjusts

Step 3: afterSwap (Fee Capture)
├─ Calculate fee: 100 TOKEN * 1% = 1 TOKEN
├─ Extract 1 TOKEN from user's output
├─ Store in internal reserves
├─ User receives: 99 TOKEN
└─ Internal state: _poolFees[poolId].amount1 += 1 TOKEN

Result:
✅ User bought TOKEN (minus 1% fee)
✅ Hook accumulated TOKEN fees
✅ Ready to convert on next sell swap
```

#### Scenario 2: Sell Swap (TOKEN → ETH) - First Sell

```
User wants to sell 50 TOKEN for ETH:
Hook has 1 TOKEN in reserves from previous buy

Step 1: beforeSwap (Internal Fill)
├─ Hook checks: Have 1 TOKEN in reserves
├─ Calculate fair price using SwapMath
├─ Price: 1 TOKEN = 0.01 ETH (example)
├─ Hook decision: Fill 1 TOKEN from internal reserves
├─ Return BeforeSwapDelta:
│  ├─ deltaSpecified: +1 TOKEN (take from user)
│  └─ deltaUnspecified: -0.01 ETH (give to user)
└─ Settlement:
   ├─ User gives hook: 1 TOKEN
   └─ Hook gives user: 0.01 ETH

Step 2: amountToSwap Modification
├─ Original: amountToSwap = -50 TOKEN
├─ Hook delta: +1 TOKEN
├─ New: amountToSwap = -49 TOKEN
└─ AMM only swaps 49 TOKEN!

Step 3: AMM Swap
├─ Uniswap swaps remaining 49 TOKEN
├─ User receives: ~0.49 ETH
└─ Total user received: 0.01 + 0.49 = 0.50 ETH

Step 4: afterSwap (Fee Capture + Distribution)
├─ Calculate fee: 0.50 ETH * 1% = 0.005 ETH
├─ Extract 0.005 ETH from output
├─ Add to internal reserves
├─ Check if ready to distribute:
│  ├─ Threshold: 0.0001 ETH
│  ├─ Balance: 0.01 + 0.005 = 0.015 ETH
│  └─ Above threshold → Distribute!
└─ Call donate(0.015 ETH, 0 TOKEN) to LPs

Result:
✅ User sold TOKEN (minus 1% fee)
✅ Hook converted 1 TOKEN to 0.01 ETH
✅ LPs received 0.015 ETH in fees
✅ Zero TOKEN in LP fees!
```

#### Scenario 3: Multiple Swaps Over Time

```
Sequence of swaps showing fee conversion:

Swap 1: Alice buys 100 TOKEN
├─ Pays: 1 ETH
├─ Hook collects: 1 TOKEN fee
└─ Internal reserves: 1 TOKEN, 0 ETH

Swap 2: Bob sells 50 TOKEN
├─ Receives: 0.50 ETH (0.49 to Bob, 0.005 fee)
├─ Hook fills: 1 TOKEN from reserves
├─ Hook collects: 0.005 ETH + 0.01 ETH = 0.015 ETH
├─ Distributed to LPs: 0.015 ETH
└─ Internal reserves: 0 TOKEN, 0 ETH

Swap 3: Charlie buys 200 TOKEN
├─ Pays: 2 ETH
├─ Hook collects: 2 TOKEN fee
└─ Internal reserves: 2 TOKEN, 0 ETH

Swap 4: Dave sells 100 TOKEN
├─ Receives: 1.00 ETH (0.99 to Dave, 0.01 fee)
├─ Hook fills: 2 TOKEN from reserves
├─ Hook collects: 0.01 ETH + 0.02 ETH = 0.03 ETH
├─ Distributed to LPs: 0.03 ETH
└─ Internal reserves: 0 TOKEN, 0 ETH

Summary After 4 Swaps:
├─ Total fees collected: 3 TOKEN + 0.045 ETH
├─ Converted to: 0.045 ETH (all TOKEN converted!)
├─ Distributed to LPs: 0.045 ETH
└─ LPs received: 100% ETH, 0% TOKEN ✅
```

---

## Technical Design

### Hook Permissions Required

```solidity
function getHookPermissions() public pure returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeInitialize: false,
        afterInitialize: false,
        beforeAddLiquidity: false,
        afterAddLiquidity: false,
        beforeRemoveLiquidity: false,
        afterRemoveLiquidity: false,
        beforeSwap: true,                      // ✅ Fill from internal reserves
        afterSwap: true,                       // ✅ Capture fees
        beforeDonate: false,
        afterDonate: false,
        beforeSwapReturnDelta: true,           // ✅ Modify amountToSwap
        afterSwapReturnDelta: true,            // ✅ Extract fees from output
        afterAddLiquidityReturnDelta: false,
        afterRemoveLiquidityReturnDelta: false
    });
}
```

### State Variables

```solidity
contract InternalSwapPool is BaseHook {
    // Immutable configuration
    uint256 public constant DONATE_THRESHOLD_MIN = 0.0001 ether;
    uint256 public constant FEE_BPS = 100;  // 1%
    uint256 public constant BPS_DENOMINATOR = 10000;
    address public immutable nativeToken;

    // Fee tracking per pool
    struct ClaimableFees {
        uint256 amount0;  // ETH fees ready to distribute
        uint256 amount1;  // TOKEN fees waiting for conversion
    }

    mapping(PoolId => ClaimableFees) internal _poolFees;

    // Events for transparency
    event FeesDeposited(PoolId indexed poolId, uint256 amount0, uint256 amount1);
    event FeesDistributed(PoolId indexed poolId, uint256 amount0);
    event InternalSwapExecuted(
        PoolId indexed poolId,
        uint256 tokenIn,
        uint256 ethOut,
        address indexed user
    );
}
```

### Core Function Flow

#### beforeSwap: Internal Pool Filling

```
Input: SwapParams from user
├─ Check: Is this TOKEN → ETH swap?
├─ Check: Do we have TOKEN reserves?
├─ If both true:
│  ├─ Get current pool price
│  ├─ Calculate how much we can fill
│  ├─ Calculate fair ETH output
│  ├─ Update internal reserves
│  ├─ Settle deltas with PoolManager
│  └─ Return BeforeSwapDelta
└─ Else: Return zero delta

Output: BeforeSwapDelta that reduces amountToSwap
```

#### afterSwap: Fee Capture and Distribution

```
Input: Delta from completed swap
├─ Determine which token user received
├─ Calculate 1% fee on output
├─ Store fee in internal reserves
├─ Extract fee using afterSwapReturnDelta
├─ Check if ETH fees above threshold
└─ If yes: Call _distributeFees()

Output: int128 delta extracting fee from output
```

#### _distributeFees: LP Reward Distribution

```
Input: PoolKey
├─ Get accumulated ETH fees
├─ Check: Above minimum threshold?
├─ If yes:
│  ├─ Call poolManager.donate()
│  ├─ Settle donation
│  └─ Reset fee counter
└─ Emit FeesDistributed event

Result: LPs receive ETH proportionally
```

---

## Design Decisions

### Why 1% Fee?

```
Comparison:
├─ Uniswap V3: 0.01%, 0.05%, 0.3%, 1%
├─ Our hook: 1% (on top of pool fee)
└─ Reasoning:
   ├─ Compensates for conversion service
   ├─ Higher than typical to fund internal operations
   └─ Can be adjusted based on token volatility
```

### Why donate() Instead of Claiming?

**Alternative Approaches:**

```
Option 1: Claimable Fees (NOT CHOSEN)
├─ LPs must call claim() to receive fees
├─ Pros: More control
├─ Cons: Gas costs, complexity, might forget
└─ Rejected: Poor UX

Option 2: Auto-Distribution via donate() (CHOSEN) ✅
├─ Hook calls donate() to add fees to pool
├─ Pros: Zero gas for LPs, automatic, simple
├─ Cons: No opting out
└─ Selected: Best UX, lowest friction
```

### Why Threshold for Distribution?

```
Problem: Gas costs for small donations
Solution: Only donate when above 0.0001 ETH

Example:
├─ Small swap: 0.00001 ETH fee collected
├─ Gas cost to donate: ~50,000 gas = 0.001 ETH
├─ Not economical!
└─ Wait until 0.0001 ETH accumulated

Trade-off:
├─ Lower threshold: More frequent, higher gas
├─ Higher threshold: Less frequent, delayed rewards
└─ 0.0001 ETH: Good balance
```

### Why Use SwapMath for Internal Pricing?

**Alternative Approaches:**

```
Option 1: Oracle Price (NOT CHOSEN)
├─ Pros: Independent price source
├─ Cons: Oracle manipulation risk, staleness
└─ Rejected: Additional attack surface

Option 2: Fixed Price (NOT CHOSEN)
├─ Pros: Predictable
├─ Cons: Doesn't track market, arbitrage risk
└─ Rejected: Unfair pricing

Option 3: Current Pool Price via SwapMath (CHOSEN) ✅
├─ Pros: Same price as AMM, fair, no arbitrage
├─ Cons: None significant
└─ Selected: Uses battle-tested math
```

### Why Only Convert TOKEN→ETH and Not Both Ways?

```
Design: Asymmetric conversion

ETH → TOKEN swaps:
└─ Collect TOKEN fees, don't convert yet

TOKEN → ETH swaps:
└─ Fill from TOKEN reserves, convert to ETH

Reasoning:
├─ Goal: Accumulate ETH for LPs
├─ Converting both ways = circular
├─ One-way conversion achieves goal
└─ Simpler logic, fewer edge cases
```

---

## Security Considerations

### Reentrancy Protection

```solidity
// Uses CEI pattern (Checks-Effects-Interactions)
function beforeSwap(...) {
    // 1. CHECKS
    if (!params.zeroForOne) revert OnlyZeroForOne();
    if (_poolFees[poolId].amount1 == 0) return (selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);

    // 2. EFFECTS
    _poolFees[poolId].amount0 += ethOut;
    _poolFees[poolId].amount1 -= tokenIn;

    // 3. INTERACTIONS
    poolManager.sync(key.currency0);
    key.currency1.settle(poolManager, address(this), tokenIn, false);
}
```

### Delta Accounting Safety

```solidity
// Always sync() before settle()
poolManager.sync(key.currency0);  // Update accounting
poolManager.sync(key.currency1);

// Then transfer tokens
poolManager.take(key.currency0, address(this), ethOut);
key.currency1.settle(poolManager, address(this), tokenIn, false);
```

### Integer Overflow Protection

```solidity
// Solidity 0.8+ has built-in overflow checks
_poolFees[poolId].amount0 += ethOut;  // Reverts on overflow
```

### Price Manipulation Resistance

```solidity
// Uses real-time pool price
// Attacker would need to:
// 1. Move pool price (costs money via slippage)
// 2. Execute internal swap (gets same price)
// 3. No profit opportunity
```

---

## Gas Optimization Strategies

### 1. Minimize Storage Reads/Writes

```solidity
// Cache storage reads
ClaimableFees memory fees = _poolFees[poolId];  // 1 SLOAD

// Work with memory
fees.amount0 += ethOut;

// Write back once
_poolFees[poolId] = fees;  // 1 SSTORE
```

### 2. Skip Unnecessary Operations

```solidity
// Don't call internal swap if no reserves
if (_poolFees[poolId].amount1 == 0) {
    return (selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
}
```

### 3. Batch Donations

```solidity
// Only donate when above threshold
if (ethFees >= DONATE_THRESHOLD_MIN) {
    poolManager.donate(...);
}
```

### 4. Use Immutable Variables

```solidity
address public immutable nativeToken;  // Cheaper to read than storage
```

---

[← Back to Learning Outcomes](./02-learning-outcomes.md) | [Next: Implementation Details →](./04-implementation-details.md)
