# Week 4: Liquidity Operator - Limit Order Hook

**Course**: Uniswap v4 Incubator (UHI-8)
**Author**: Allan Robinson
**Week**: 4
**Topic**: Building a Limit Order Hook with Tick-Based Execution

---

## Overview

This week covers the implementation of a limit order hook for Uniswap v4. This hook enables users to place take-profit orders that execute automatically when price crosses a specified tick. It demonstrates advanced hook patterns including tick tracking, recursive execution prevention, and ERC-1155 token integration.

---

## What You'll Learn

### Core Concepts

1. **Limit Orders and Take-Profit Orders**
   - Understanding order book mechanics
   - Tick-based price targeting
   - Automatic order execution

2. **Tick Tracking**
   - Monitoring tick movements across swaps
   - Determining which orders are eligible
   - Handling tick shifts from order execution

3. **ERC-1155 Integration**
   - Using ERC-1155 for claim tokens
   - Proportional redemption calculations
   - Multi-user order aggregation

4. **Complex Hook Patterns**
   - Recursive execution prevention
   - State management across swaps
   - Dynamic order eligibility checking

---

## Folder Structure

```
week-4/
├── study-notes/
│   ├── 01-limit-orders-intro.md           # Introduction and mechanism design
│   ├── 02-limit-orders-part2.md           # afterSwap implementation
│   └── 03-class-questions-answered.md     # Questions from workshop
│
├── tests-homework/
│   ├── src/LimitOrder.sol                 # Main hook implementation
│   ├── test/LimitOrder.t.sol              # Comprehensive test suite
│   ├── script/Deploy.s.sol                # Deployment script
│   ├── README.md                          # Technical documentation
│   ├── HOMEWORK_ASSIGNMENT.md             # Assignment details
│   └── foundry.toml                       # Foundry configuration
│
├── resources/                             # Additional materials
├── practice/                              # Practice exercises
└── README.md                              # This file
```

---

## Study Notes Summary

### 01: Introduction and Mechanism Design

**Topics Covered**:
- What are limit orders and take-profit orders
- How tick movements trigger order execution
- Why we use afterSwap for execution
- ERC-1155 claim token design
- Simplifying assumptions

**Key Takeaways**:
- Orders execute when price crosses specific ticks
- afterSwap detects tick crossings and triggers execution
- Multiple users can place same order parameters
- ERC-1155 enables proportional redemption

### 02: Part 2 - afterSwap Implementation

**Topics Covered**:
- Tracking last known ticks
- Preventing recursive afterSwap calls
- Handling tick shifts from order execution
- Implementing tryExecutingOrders
- Testing strategies

**Key Takeaways**:
- Must track last tick to know what changed
- Sender check prevents infinite recursion
- Each order execution changes state - must re-check eligibility
- While loop pattern for iterative order execution

### 03: Class Questions Answered

**Questions Addressed**:
1. Are we filling orders at exact tick or in a range?
2. Are orders pool-specific or global?
3. How to handle v4-periphery BaseHook import changes?

**Key Answers**:
- Orders only execute at exact ticks that are crossed
- Orders are completely pool-specific (tracked by PoolId)
- BaseHook moved from `src/base/hooks/` to `src/utils/`

---

## Homework Assignment

### Objective

Build a fully functional Limit Order Hook that implements:
- Order placement and cancellation
- Automatic execution in afterSwap
- Token redemption with ERC-1155 claim tokens
- Comprehensive test suite

### Status: COMPLETED

All requirements met:
- [x] Core functionality implemented
- [x] 12+ comprehensive tests passing
- [x] Professional documentation
- [x] Repository public on GitHub
- [x] Ready for UHI quest submission

See `tests-homework/HOMEWORK_ASSIGNMENT.md` for complete details.

---

## Technical Highlights

### Key Features Implemented

**1. Tick-Based Execution**
```solidity
function tryExecutingOrders(
    PoolKey calldata key,
    bool executeZeroForOne
) internal returns (bool tryMore, int24 newTick)
```
- Iterates through crossed ticks
- Executes eligible orders
- Returns whether to check again

**2. Recursive Protection**
```solidity
if (sender == address(this)) return (this.afterSwap.selector, 0);
```
- Prevents infinite loop when hook swaps
- Critical for stability

**3. Dynamic Eligibility**
```solidity
while (tryMore) {
    (tryMore, currentTick) = tryExecutingOrders(key, !params.zeroForOne);
}
```
- Re-checks after each execution
- Handles tick shifts correctly

**4. Proportional Redemption**
```solidity
uint256 outputAmount = inputAmountToClaimFor.mulDivDown(
    totalClaimableForPosition,
    totalInputAmountForPosition
);
```
- Fair distribution among multiple users
- ERC-1155 based

---

## Testing Coverage

### Test Categories

**Basic Functionality**:
- Order placement
- Order cancellation
- Token transfers

**Execution Logic**:
- zeroForOne order execution
- oneForZero order execution
- Multiple orders - partial execution
- Multiple orders - full execution

**Edge Cases**:
- Recursive prevention
- Partial redemption
- Bidirectional orders
- Tick boundary conditions

**Results**: All tests passing

---

## Key Learning Outcomes

After completing this week, you should understand:

1. **How limit orders work on-chain**
   - Order placement and storage
   - Automatic execution triggers
   - Claim token mechanics

2. **Advanced hook patterns**
   - Multiple hook permissions
   - State tracking across calls
   - Recursive execution handling

3. **Tick mechanics in depth**
   - Tick spacing and valid ticks
   - Tick movements and price changes
   - Order eligibility based on ticks

4. **Production considerations**
   - Gas optimization needs
   - Slippage protection requirements
   - Scalability challenges

---

## Common Challenges

### Challenge 1: Understanding Tick Direction

**Problem**: Confusion about which direction orders should execute

**Solution**:
- Tick increases → Token 0 price up → Execute sell Token 0 orders
- Tick decreases → Token 1 price up → Execute sell Token 1 orders

### Challenge 2: Order Execution Affecting State

**Problem**: Orders become ineligible after other orders execute

**Solution**: Always re-check eligibility after each execution, don't batch execute

### Challenge 3: Import Path Issues

**Problem**: BaseHook not found

**Solution**: Check v4-periphery version, try both import paths

### Challenge 4: Test Contract ERC-1155 Issues

**Problem**: Tests fail with ERC1155InvalidReceiver error

**Solution**: Inherit from ERC1155Holder in test contract

---

## Production Improvements

To make this production-ready, add:

1. **Gas Limits**
   - Limit orders executed per swap
   - Prevent DoS of swappers

2. **Slippage Protection**
   - Allow users to set max slippage
   - Revert if exceeded

3. **Time Limits**
   - Add order expiration
   - Auto-cancel expired orders

4. **Partial Fills**
   - Allow orders to partially fill
   - Track remaining amounts

5. **Native ETH Support**
   - Handle WETH wrapping/unwrapping
   - Support ETH pairs

6. **Order Priority**
   - Define execution order for same tick
   - Consider fees or timestamps

---

## Resources

### Official Documentation
- [Uniswap v4 Documentation](https://docs.uniswap.org/contracts/v4)
- [Hook Development Guide](https://docs.uniswap.org/contracts/v4/guides/hook-development)
- [Foundry Book](https://book.getfoundry.sh/)

### Reference Implementations
- [Take Profits Hook by Haardik](https://github.com/haardikk21/take-profits-hook)
- [v4-core Tests](https://github.com/Uniswap/v4-core/tree/main/test)

### Additional Reading
- [ERC-1155 Standard](https://eips.ethereum.org/EIPS/eip-1155)
- [Tick Math Explained](https://uniswapv3book.com/docs/introduction/constant-function-market-maker/)

---

## Next Steps

1. **Review Implementation**
   - Study the completed code in tests-homework/
   - Understand each component's role
   - Run tests and observe behavior

2. **Experiment with Variations**
   - Modify order execution logic
   - Add new features (expiration, partial fills)
   - Optimize gas costs

3. **Prepare for Hackathon**
   - Think of novel hook ideas
   - Practice building hooks quickly
   - Study other hook implementations

4. **Continue Learning**
   - Move on to Week 5 materials
   - Attend workshops and office hours
   - Engage with the community

---

## Questions or Issues?

- **During Workshops**: Ask questions in real-time
- **Office Hours**: Get personalized help
- **Group Chat**: Collaborate with peers
- **Documentation**: Refer to study notes

---

**Week Status**: COMPLETED
**Homework Status**: SUBMITTED
**Ready for**: Week 5 and Hackathon Preparation

Keep building, keep learning, and good luck with your Hookathon project!
