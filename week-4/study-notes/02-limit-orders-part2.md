# Liquidity Operator: Limit Order Hook - Part 2

**Author**: Allan Robinson
**Date**: February 2026
**Topic**: Implementing afterSwap and Order Execution Logic

---

## Lesson Objectives

- Understand how to track tick movements inside afterSwap
- Learn about possible issues with swapping inside a hook, recursively
- Build out the remainder of the limit order hook
- Complete the end-to-end implementation

---

## Recap from Part 1

So far we have built:
- `placeOrder()` - Users can place limit orders
- `cancelOrder()` - Users can cancel pending orders
- `redeem()` - Users can redeem output tokens after execution
- `executeOrder()` - Internal function to execute a single order

The `executeOrder()` function isn't used anywhere yet. We need to implement the hook functions to make it work.

---

## Mechanism Design for afterSwap

We discussed that the way to execute a swap will be to:
1. Check inside **afterSwap** if the tick has shifted from the last known tick
2. Check if we have any pending orders within that range
3. Execute those orders

This gives us our first hint: **We need to track "last known" ticks for different pools.**

---

## Critical Considerations

### 1. Tracking Last Known Ticks

afterSwap only tells us the "new"/current tick - not what it was before.

**Solution**: Create a mapping in storage to keep track of last known ticks.

```solidity
mapping(PoolId poolId => int24 lastTick) public lastTicks;
```

### 2. Preventing Recursive afterSwap Calls

Since we are executing a swap inside afterSwap, this itself will trigger another execution of afterSwap internally.

This can lead to:
- Too much recursion
- Re-entrancy attacks
- Stack-too-deep errors

**Solution**: Check if the sender is the hook contract itself and exit early.

### 3. Tick Shifts from Order Execution

**This is the most important consideration!**

As we fulfill each order, the tick shifts even more. We cannot simply execute all orders that existed within the original tick shift.

#### Example Scenario

**Initial State**:
- Pool at tick 500
- Alice has orders at ticks 550 and 600 (both will make tick go down if executed)

**Bob's Swap**:
- Bob swaps and increases tick from 500 to 650
- Both of Alice's orders appear to be in range

**The Problem**:
1. We execute Alice's order at tick 550
2. This execution makes the tick drop (maybe to 580)
3. Now Alice's second order at tick 600 can NO LONGER be fulfilled
4. Even though both orders were in the original range!

**The Solution**:
- Keep track of how each individual order execution updates tick values
- Don't execute all orders in original range blindly
- Re-check eligibility after each execution

---

## Implementation: afterInitialize

When a pool is initialized, its current tick is set for the first time. We need to store this as our "last known tick".

```solidity
function _afterInitialize(
    address,
    PoolKey calldata key,
    uint160,
    int24 tick
) internal override returns (bytes4) {
    lastTicks[key.toId()] = tick;
    return this.afterInitialize.selector;
}
```

Simple! Just one line of logic.

---

## Implementation: afterSwap

### The Core Logic

```solidity
function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta,
    bytes calldata
) internal override returns (bytes4, int128) {
    // Prevent recursive execution
    if (sender == address(this)) return (this.afterSwap.selector, 0);

    // Try executing orders
    bool tryMore = true;
    int24 currentTick;

    while (tryMore) {
        (tryMore, currentTick) = tryExecutingOrders(
            key,
            !params.zeroForOne
        );
    }

    // Update last known tick
    lastTicks[key.toId()] = currentTick;
    return (this.afterSwap.selector, 0);
}
```

### Breaking It Down

**Step 1: Prevent Recursion**
```solidity
if (sender == address(this)) return (this.afterSwap.selector, 0);
```
- `sender` is the address that initiated the swap
- When our hook fulfills an order and does a swap, sender is the hook itself
- We exit early to prevent recursive loops

**Step 2: Execute Orders Loop**
```solidity
while (tryMore) {
    (tryMore, currentTick) = tryExecutingOrders(
        key,
        !params.zeroForOne
    );
}
```
- Keep trying to fulfill orders while there are orders to execute
- Each iteration re-checks eligibility based on updated tick
- `tryExecutingOrders` returns:
  - `tryMore`: true if an order was executed (need to check again)
  - `currentTick`: updated tick after execution

**Step 3: Update Last Known Tick**
```solidity
lastTicks[key.toId()] = currentTick;
```
- Store the final tick value after all executions
- This becomes the baseline for the next swap

---

## Implementation: tryExecutingOrders

This is the most complex function. It needs to:
1. Get current tick and last tick
2. Determine direction of tick movement
3. Find orders in the tick range
4. Execute one order if found
5. Return whether to try again

### Core Structure

```solidity
function tryExecutingOrders(
    PoolKey calldata key,
    bool executeZeroForOne
) internal returns (bool tryMore, int24 newTick) {
    (, int24 currentTick, , ) = poolManager.getSlot0(key.toId());
    int24 lastTick = lastTicks[key.toId()];

    // Case 1: Tick increased (currentTick > lastTick)
    // Case 2: Tick decreased (currentTick < lastTick)

    // ... handle each case ...

    return (false, currentTick);
}
```

### Case 1: Tick Increased

Tick increased → Token 0 price increased → Check for sell Token 0 orders

```solidity
if (currentTick > lastTick) {
    for (
        int24 tick = lastTick;
        tick < currentTick;
        tick += key.tickSpacing
    ) {
        uint256 inputAmount = pendingOrders[key.toId()][tick][
            executeZeroForOne
        ];
        if (inputAmount > 0) {
            executeOrder(key, tick, executeZeroForOne, inputAmount);
            return (true, currentTick);
        }
    }
}
```

**Why loop from lastTick to currentTick?**
- We check every possible tick where an order could exist
- We execute the first one we find
- Return immediately to re-check the range

### Case 2: Tick Decreased

Tick decreased → Token 1 price increased → Check for sell Token 1 orders

```solidity
else {
    for (
        int24 tick = lastTick;
        tick > currentTick;
        tick -= key.tickSpacing
    ) {
        uint256 inputAmount = pendingOrders[key.toId()][tick][
            executeZeroForOne
        ];
        if (inputAmount > 0) {
            executeOrder(key, tick, executeZeroForOne, inputAmount);
            return (true, currentTick);
        }
    }
}
```

### Why Return After Each Execution?

After executing one order:
- The tick has shifted
- Previously eligible orders might no longer be eligible
- We need to re-calculate the tick range
- The while loop in afterSwap will iterate again with the new tick

---

## Testing Strategy

### Test 1: Execute zeroForOne Order

Place order to sell Token 0 at tick 100, then swap to increase tick past 100, verify order executes.

### Test 2: Execute oneForZero Order

Place order to sell Token 1 at tick -100, then swap to decrease tick past -100, verify order executes.

### Test 3: Multiple Orders - Only One Executes

Place two orders at ticks 0 and 60. Swap such that:
- Tick crosses both 0 and 60
- First order execution brings tick back down
- Second order should NOT execute

### Test 4: Multiple Orders - Both Execute

Place two orders at ticks 0 and 60. Swap with larger amount such that:
- Tick crosses both 0 and 60
- Even after first order executes, tick is still high enough
- Second order should also execute

---

## Key Insights

### Insight 1: Recursive Protection is Critical

Without checking `sender == address(this)`, the hook would enter infinite recursion:
- afterSwap executes order
- Order swap triggers afterSwap again
- That triggers another swap
- Stack overflow!

### Insight 2: Order Execution Changes State

Each order execution:
- Moves the tick
- Reduces pending orders
- Changes claimable amounts
- Affects what orders are still executable

### Insight 3: While Loop Pattern

The pattern of:
```solidity
while (tryMore) {
    (tryMore, currentTick) = tryExecutingOrders(...);
}
```

Is powerful because:
- Keeps trying to execute orders
- Rechecks eligibility after each execution
- Naturally terminates when no more orders are executable

---

## Production Considerations

For a production-ready hook, you would need to add:

1. **Gas Limits**: Limit number of orders executed per swap to prevent DoS
2. **Slippage Protection**: Allow users to set maximum acceptable slippage
3. **Native ETH Support**: Handle pools with ETH as one token
4. **Partial Fills**: Allow orders to be partially filled across multiple swaps
5. **Time Limits**: Add expiration times for orders
6. **Priority/Ordering**: Define how to prioritize orders at same tick

---

## Common Pitfalls

### Pitfall 1: Not Updating Last Tick

If you forget to update `lastTicks[poolId]`, every swap will try to execute ALL historical orders.

### Pitfall 2: Executing All Orders at Once

If you don't return after each execution, you'll execute orders that should no longer be eligible.

### Pitfall 3: Wrong Loop Direction

Looping in wrong direction (e.g., down when tick increased) will find no orders or wrong orders.

### Pitfall 4: No Recursive Protection

Without sender check, hook will crash due to stack overflow.

---

## Conclusion

This module was a bump-up in difficulty from previous lessons. Key learnings:

1. **afterSwap** can trigger order execution automatically
2. **Tick tracking** is essential for knowing what changed
3. **Recursive protection** prevents infinite loops
4. **Order execution** changes state - must re-check eligibility
5. **ERC-1155** enables proportional claim redemption

This is the first "real" hook design we've done - and demonstrates the power of hooks to create completely new behaviors in Uniswap.

---

## Homework

Build a limit order hook using the instructions in this lesson. Once completed, submit the form to confirm you're on track with UHI.

**Requirements**:
- Hook must be public on GitHub
- Must implement all core functionality
- Tests should pass
- Professional documentation

Remember: It's okay if it's not perfect! The goal is to learn and practice.
