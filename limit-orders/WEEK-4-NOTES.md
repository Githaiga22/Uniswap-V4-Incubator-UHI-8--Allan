# Week-4 Lesson Notes: Liquidity Operator - Limit Order Hook

**Assignment**: Implement a limit order hook for Uniswap v4 using tick-based execution and ERC-1155 claim tokens.

---

## Key Concepts Learned

### 1. Tick-Based Order Execution

**What are Ticks?**
- Ticks are discrete price points in Uniswap v4
- Each tick represents a 0.01% price change
- Formula: `price = 1.0001^tick`
- Tick spacing depends on fee tier (e.g., 60 for 0.3% pools)

**Tick Tracking**:
```solidity
// Store last known tick for each pool
mapping(PoolId => int24) public lastTicks;

// After each swap, compare ticks to detect crossings
function afterSwap(...) {
    (, int24 currentTick, , ) = poolManager.getSlot0(poolId);
    int24 prevTick = lastTicks[poolId];

    // Determine range of crossed ticks
    int24 lower = params.zeroForOne ? currentTick : prevTick;
    int24 upper = params.zeroForOne ? prevTick : currentTick;

    // Execute orders in this range
    tryExecutingOrders(key, lower, upper, params.zeroForOne);

    // Update for next time
    lastTicks[poolId] = currentTick;
}
```

### 2. afterSwap Hook Execution

**Purpose**: Execute limit orders automatically when price crosses target ticks

**Workflow**:
1. User swaps tokens → price moves → ticks crossed
2. PoolManager calls `afterSwap` hook
3. Hook detects which ticks were crossed
4. Hook executes orders at those ticks
5. Hook stores output tokens for later redemption

**Important Constraint**: Hook execution happens WITHIN the swap transaction
- Must be gas-efficient
- Cannot revert (would fail the swap)
- Use bounded iteration

### 3. ERC-1155 Claim Tokens

**Why ERC-1155?**
- **Fungible per order**: All claim tokens from same order ID are identical
- **Multiple order IDs**: Each order gets unique token ID
- **Proportional redemption**: Users can redeem partial amounts
- **Transferable**: Claim tokens can be traded before redemption

**Implementation**:
```solidity
contract LimitOrder is BaseHook, ERC1155 {
    // Place order → mint claim tokens
    function placeOrder(...) {
        uint256 orderId = nextOrderId++;
        _mint(msg.sender, orderId, amount, "");
    }

    // Cancel order → burn claim tokens
    function cancelOrder(...) {
        _burn(msg.sender, orderId, amount);
    }

    // Redeem output → burn proportionally
    function redeem(...) {
        uint256 userShare = (totalClaimable * amount) / order.amount;
        _burn(msg.sender, orderId, amount);
        // Transfer proportional output
    }
}
```

### 4. Delta Accounting in unlockCallback

**What is unlock()?**
- PoolManager uses unlock pattern for atomic operations
- All state changes happen within unlock window
- Must settle net deltas before unlock ends

**Pattern**:
```solidity
function unlockCallback(bytes calldata data)
    external
    override
    onlyPoolManager
    returns (bytes memory)
{
    // 1. Execute swap
    BalanceDelta delta = poolManager.swap(key, params, "");

    // 2. Settle input (hook pays pool)
    //    Hook has tokens, needs to give them to pool
    poolManager.settle(inputCurrency);

    // 3. Take output (pool pays hook)
    //    Pool has tokens, hook needs to take them
    poolManager.take(outputCurrency, address(this), amountOut);

    // Return data to caller
    return abi.encode(amountOut);
}
```

**Key Insight**: settle() and take() are opposite directions
- `settle()`: Move tokens FROM hook TO pool
- `take()`: Move tokens FROM pool TO hook

### 5. Recursive Swap Prevention

**Problem**: Hook executes swaps during afterSwap
- If hook's own swaps trigger afterSwap again, infinite recursion!

**Solution**: Check sender
```solidity
function afterSwap(address sender, ...) {
    // If hook is the sender, it's our own swap - don't recurse
    if (sender == address(this)) {
        return (BaseHook.afterSwap.selector, 0);
    }

    // Otherwise, proceed with order execution
    ...
}
```

---

## Class Questions & Answers

### Q1: "Are we filling orders that hit the tick line or every order in the range even if it doesn't hit the line?"

**Answer**: We fill orders AT THE EXACT TICK that was crossed.

**Explanation**:
- When price moves from tick 0 to tick 120, we check ticks: 0, 60, 120 (depending on tick spacing)
- Orders at tick 60: **Execute** [x]
- Orders at tick 50: **Do NOT execute** [ ] (tick not crossed)
- Orders at tick 80: **Do NOT execute** [ ] (tick not crossed)
- Orders at tick 120: **Execute** [x]

**Code**:
```solidity
for (int24 tick = lowerTick; tick <= upperTick; tick++) {
    if (orderCounts[poolId][tick] == 0) continue; // Skip ticks with no orders

    // Execute orders at THIS tick
    for (uint256 i = 0; i < nextOrderId; i++) {
        if (orders[i].tick == tick && !orders[i].executed) {
            executeOrder(i, key);
        }
    }
}
```

### Q2: "Our orders will track only the LP which has this hook activated and not other LPs right?"

**Answer**: Orders are **pool-specific**, tracked by `PoolId`. Only the pool with this hook can have limit orders.

**Explanation**:
```
Pool A: USDC/ETH, 0.3% fee, LimitOrder hook
  → PoolId A = hash(currency0, currency1, fee, tickSpacing, hook)
  → Orders stored in: orderCounts[PoolId A][tick]

Pool B: USDC/ETH, 1% fee, different hook
  → PoolId B = hash(currency0, currency1, fee, tickSpacing, differentHook)
  → Separate order book

Pool A orders ≠ Pool B orders
```

**Code**:
```solidity
function placeOrder(PoolKey calldata key, ...) {
    PoolId poolId = key.toId(); // Unique per pool
    orderCounts[poolId][tick]++; // Pool-specific storage
}
```

### Q3: v4-periphery BaseHook Updates

**What Changed?**
- v4-periphery updated BaseHook to include:
  - `onlyPoolManager` modifier for security
  - Proper delta handling patterns
  - Helper functions for common operations

**How to Use**:
```solidity
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";

contract LimitOrder is BaseHook, ERC1155 {
    constructor(IPoolManager _poolManager)
        BaseHook(_poolManager)
        ERC1155("")
    {}

    function afterSwap(...)
        external
        override
        onlyPoolManager // ← Security: only PoolManager can call
        returns (bytes4, int128)
    {
        ...
    }
}
```

**Benefits**:
- **Security**: Prevents unauthorized hook calls
- **Simplicity**: Boilerplate handled by BaseHook
- **Compatibility**: Works with latest v4 architecture

---

## Implementation Challenges & Solutions

### Challenge 1: Gas Cost of Order Execution

**Problem**: Iterating through all orders to find matches is expensive

**Solution**:
- Track order count per tick: `orderCounts[poolId][tick]`
- Skip ticks with zero orders
- Gas-limited iteration (fail gracefully, don't revert swap)

### Challenge 2: Output Token Storage

**Problem**: Orders execute at different times, need to store output for each order

**Solution**:
- Store claimable amount per order ID
- Use ERC-1155 for claim tokens
- Proportional redemption based on claim token balance

### Challenge 3: Order vs. Swap Direction Matching

**Problem**: Buy orders should execute when price goes UP, sell orders when price goes DOWN

**Solution**:
```solidity
// Only execute orders in the same direction as price movement
if (order.zeroForOne == params.zeroForOne) {
    executeOrder(i, key);
}
```

---

## Testing Strategy

### 1. Basic Functionality
- Place order
- Cancel order
- Execute order on tick crossing
- Redeem output tokens

### 2. Edge Cases
- Order NOT executed if tick not crossed
- Multiple orders at same tick
- Bidirectional orders (buy and sell)
- Partial redemption

### 3. Gas Optimization
- Benchmark gas costs
- Ensure bounded execution
- Verify swaps don't fail due to order execution

---

## Key Takeaways

1. **Ticks are Price Points**: Limit orders use tick-based triggers
2. **afterSwap Detects Crossings**: Compare current tick to last tick
3. **ERC-1155 for Claims**: Fungible per order, proportional redemption
4. **Delta Accounting**: settle() vs take() are opposite directions
5. **Recursive Prevention**: Check sender to avoid infinite loops
6. **Pool-Specific Orders**: Each PoolId has separate order book
7. **Gas Efficiency**: Bounded iteration, don't revert on failure

---

## Further Improvements

1. **Time-Limited Orders**: Add expiration timestamps
2. **Stop-Loss Orders**: Trigger on price conditions
3. **Order Aggregation**: Batch orders at same tick
4. **Partial Fills**: Allow orders to be filled across multiple swaps
5. **Order Book View**: Gas-efficient view function for all orders

---

## References

- [Uniswap v4 Documentation](https://docs.uniswap.org/contracts/v4)
- [Hook Development Guide](https://docs.uniswap.org/contracts/v4/guides/hook-development)
- [ERC-1155 Standard](https://eips.ethereum.org/EIPS/eip-1155)
- [Tick Math Explanation](https://uniswapv3book.com/docs/introduction/constant-function-market-maker/)

---

**Assignment Completed**: February 2026
**Topics Covered**: Limit Orders, Tick Tracking, afterSwap Hook, ERC-1155 Claim Tokens, Delta Accounting
