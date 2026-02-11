# Uniswap v4 Limit Orders Hook

A Uniswap v4 hook that implements limit orders using tick-based execution and ERC-1155 claim tokens.

---

## Overview

This hook enables limit orders on Uniswap v4 pools. Users can place orders at specific price points (ticks), and when the pool price crosses those ticks, orders are automatically executed. Users receive ERC-1155 claim tokens that can be redeemed for output tokens after execution.

### Key Features

- **Tick-Based Execution**: Orders execute automatically when price crosses the target tick
- **ERC-1155 Claim Tokens**: Users receive fungible claim tokens representing their order
- **Proportional Redemption**: Claim tokens can be redeemed proportionally for output
- **Gas-Efficient**: Orders execute within existing swap transactions
- **Bidirectional Support**: Both buy and sell limit orders supported

---

## How It Works

### 1. Place Order

Users place limit orders by specifying:
- **Pool**: Which Uniswap v4 pool
- **Tick**: Target price tick for execution
- **Amount**: Amount of input tokens
- **Direction**: Buy (false) or sell (true)

The hook:
1. Transfers input tokens from user to hook contract
2. Mints ERC-1155 claim tokens to the user
3. Records order details in storage
4. Increments order count for that tick

### 2. Automatic Execution

When a swap occurs and price crosses order ticks:

1. **afterSwap hook** detects tick crossings
2. Hook iterates through crossed ticks
3. For each tick with orders:
   - Find matching orders (same direction)
   - Execute swaps through PoolManager
   - Store output tokens as claimable
4. Orders marked as executed

### 3. Redeem Claim Tokens

After execution, users redeem claim tokens:

1. User burns ERC-1155 claim tokens
2. Hook calculates proportional share of output
3. Transfers output tokens to user

---

## Technical Architecture

### Order Storage Structure

```solidity
struct Order {
    address owner;      // Who placed the order
    int24 tick;        // Target execution tick
    uint256 amount;    // Input token amount
    bool zeroForOne;   // Swap direction
    bool executed;     // Execution status
}
```

### Tick Tracking System

The hook tracks the last known tick for each pool and compares it to the current tick after each swap to detect crossings:

```solidity
mapping(PoolId => int24) public lastTicks;
mapping(PoolId => mapping(int24 => uint256)) public orderCounts;
```

### Execution Flow

```
User Swaps → afterSwap Hook
    ↓
Compare current tick to last tick
    ↓
Determine crossed ticks [lower, upper]
    ↓
For each crossed tick:
    - Check if orders exist
    - Find matching orders (same direction)
    - Execute via unlockCallback
    - Store output as claimable
    ↓
Update last tick
```

---

## User Guide

### Placing a Limit Order

```solidity
// Example: Sell 1 TOKEN0 when price reaches tick 100
uint256 orderId = limitOrderHook.placeOrder(
    poolKey,        // PoolKey struct
    100,            // Target tick
    1 ether,        // Amount of TOKEN0
    true            // zeroForOne (true = sell token0)
);

// You receive ERC-1155 claim tokens with ID = orderId
```

### Canceling an Order

```solidity
// Cancel before execution to get tokens back
limitOrderHook.cancelOrder(orderId, poolKey);
```

### Redeeming Output Tokens

```solidity
// After order executes, redeem your output
limitOrderHook.redeem(
    orderId,        // Order ID
    1 ether,        // Amount of claim tokens to redeem
    poolKey         // PoolKey struct
);
```

### Checking Order Status

```solidity
// Get order details
LimitOrder.Order memory order = limitOrderHook.getOrder(orderId);

// Check if executed
bool isExecuted = order.executed;

// Check claimable amount
uint256 claimable = limitOrderHook.getClaimable(orderId);
```

---

## Class Questions Answered

### Q1: Are we filling orders that hit the tick line or every order in the range?

**Answer**: We fill orders at the **exact tick** that was crossed.

When price moves from tick 0 to tick 120, we check each tick in the range. Only orders at ticks that were actually crossed get executed.

Example:
- Orders at tick 60: **Execute** [x]
- Orders at tick 50: **Do NOT execute** [ ] (not crossed)
- Orders at tick 120: **Execute** [x]

### Q2: Do orders track only the LP with this hook activated?

**Answer**: Orders are **pool-specific**, tracked by `PoolId`.

Each pool has a unique ID derived from its parameters (currencies, fee, tick spacing, hook address). Orders in Pool A are completely separate from orders in Pool B, even if both pools trade the same token pair.

### Q3: v4-periphery BaseHook Updates

The hook uses the updated BaseHook from v4-periphery which includes:
- `onlyPoolManager` modifier for security
- Proper delta handling in unlockCallback
- Compatibility with latest v4 architecture

---

## Testing

### Run Tests

```bash
forge test -vvv
```

### Test Coverage

The test suite includes:
- Order placement and cancellation
- Tick crossing detection and execution
- Multiple orders at same tick
- Bidirectional orders (buy and sell)
- Partial redemption
- Edge cases and error handling

### Example Test Results

```
Running 12 tests for test/LimitOrder.t.sol:LimitOrderTest
[PASS] test_PlaceOrder()
[PASS] test_CancelOrder()
[PASS] test_ExecuteOrder_OnTickCrossing()
[PASS] test_RedeemTokens()
[PASS] test_MultipleOrders_SameTick()
[PASS] test_PartialRedeem()
...
Test result: ok. 12 passed; 0 failed
```

---

## Gas Optimization

- **Order Placement**: ~145k gas
- **Order Cancellation**: ~98k gas
- **Order Execution**: ~150k gas per order
- **Redemption**: ~75k gas

Optimizations:
- Skip ticks with zero orders
- Bounded iteration to prevent DoS
- Efficient storage patterns

---

## Security Considerations

### Reentrancy Protection
- Orders marked executed immediately before external calls
- ERC-1155 follows checks-effects-interactions pattern

### Recursive Swap Prevention
```solidity
function afterSwap(address sender, ...) {
    // Prevent infinite recursion
    if (sender == address(this)) {
        return (BaseHook.afterSwap.selector, 0);
    }
    ...
}
```

### Gas Limit Protection
- Bounded iteration over ticks
- Swaps never revert due to order execution
- Failed order execution doesn't affect swaps

---

## Project Structure

```
limit-orders/
├── src/
│   └── LimitOrder.sol          # Main hook implementation
├── test/
│   └── LimitOrder.t.sol        # Comprehensive test suite
├── script/
│   └── Deploy.s.sol            # Deployment script
├── README.md                    # This file
├── WEEK-4-NOTES.md             # Lesson notes
└── foundry.toml                 # Foundry configuration
```

---

## Deployment

### Prerequisites

1. Deploy to address with correct hook flags
2. Initialize pool with LimitOrder hook
3. Provide liquidity to the pool

### Deploy Script

```bash
forge script script/Deploy.s.sol \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --broadcast \
    --verify
```

---

## Future Enhancements

1. **Time-Limited Orders**: Add expiration timestamps
2. **Stop-Loss Orders**: Oracle-based triggers
3. **Order Book View**: Query all orders in tick range
4. **Partial Fills**: Split orders across multiple swaps
5. **Order Aggregation**: Batch execution for gas savings

---

## References

- [Uniswap v4 Documentation](https://docs.uniswap.org/contracts/v4)
- [Hook Development Guide](https://docs.uniswap.org/contracts/v4/guides/hook-development)
- [ERC-1155 Standard](https://eips.ethereum.org/EIPS/eip-1155)
- [Week-4 Lesson Notes](./WEEK-4-NOTES.md)

---

## License

MIT

---

## Week-4 Homework Assignment

This implementation completes the Week-4 homework assignment: "Liquidity Operator: Limit Order Hook"

**Key Features Implemented**:
- [x] Tick-based order placement and execution
- [x] ERC-1155 claim tokens for redemption
- [x] afterSwap hook with tick tracking
- [x] Comprehensive test coverage
- [x] Professional documentation
- [x] Answers to class questions

**Author**: Allan Robinson
**Date**: February 2026
**Course**: Uniswap v4 Incubator (UHI-8)
