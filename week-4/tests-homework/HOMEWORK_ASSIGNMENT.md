# Week-4 Homework: Limit Order Hook Implementation

**Course**: Uniswap v4 Incubator (UHI-8)
**Author**: Allan Robinson
**Date**: February 2026
**Topic**: Building a Limit Order Hook for Uniswap v4

---

## Assignment Overview

The goal of this exercise is to build a Limit Order Hook based on the instructions in the curriculum lessons. Continuing to build hooks is the single best way to prep yourself for a successful Hookathon.

---

## Requirements

### Core Functionality

Your Limit Order Hook must implement:

1. **Order Placement**
   - `placeOrder()` function
   - Users can specify tick, direction (zeroForOne), and amount
   - Transfers input tokens to hook
   - Mints ERC-1155 claim tokens to user

2. **Order Cancellation**
   - `cancelOrder()` function
   - Returns input tokens to user
   - Burns claim tokens

3. **Order Execution**
   - Automatic execution in `afterSwap` hook
   - Tracks tick movements
   - Executes orders when tick crosses order tick
   - Prevents recursive execution

4. **Token Redemption**
   - `redeem()` function
   - Burns claim tokens
   - Transfers proportional output tokens to user

### Technical Requirements

- [x] Solidity ^0.8.26
- [x] Foundry as build tool
- [x] Inherits from BaseHook and ERC1155
- [x] Uses v4-core and v4-periphery
- [x] Comprehensive test suite
- [x] Repository must be public on GitHub

---

## UHI Quest Submission

Complete the official UHI quest form to track your progress:

### Quest Questions

**1. Have you attended the Limit Order Workshops or watched the recordings?**
- The Workshop recordings are available if you need to review
- Workshops took place on November 10th and 13th

**2. Have you reviewed the Liquidity Operator: Limit Order Hook lesson in the Curriculum?**
- Review the lessons in week-4/study-notes if needed

**3. Have you built your Limit Order hook?**
- Make sure your repository is public
- It's okay if it's not perfect

**4. Share a link to your hook repo**
- Repository: https://github.com/Githaiga22/Uniswap-V4-Incubator-UHI-8--Allan
- Location: `/week-4/tests-homework/` or `/limit-orders/`

---

## Implementation Status

### Completed Features

- [x] Project setup with Foundry
- [x] BaseHook structure with proper permissions
- [x] ERC-1155 integration for claim tokens
- [x] `placeOrder()` implementation
- [x] `cancelOrder()` implementation
- [x] `redeem()` implementation
- [x] `executeOrder()` internal function
- [x] `afterInitialize()` hook for tick tracking
- [x] `afterSwap()` hook with order execution logic
- [x] `tryExecutingOrders()` helper function
- [x] `swapAndSettleBalances()` helper function
- [x] Comprehensive test suite (12+ tests)
- [x] Professional documentation

### Test Coverage

**Basic Functionality Tests**:
- [x] `test_placeOrder()` - Verify order placement
- [x] `test_cancelOrder()` - Verify order cancellation

**Execution Tests**:
- [x] `test_orderExecute_zeroForOne()` - Execute sell Token0 order
- [x] `test_orderExecute_oneForZero()` - Execute sell Token1 order

**Multiple Order Tests**:
- [x] `test_multiple_orderExecute_zeroForOne_onlyOne()` - First order execution prevents second
- [x] `test_multiple_orderExecute_zeroForOne_both()` - Both orders execute
- [x] Partial redemption tests
- [x] Bidirectional order tests

All tests passing with forge test.

---

## Key Features Implemented

### 1. Tick-Based Execution

Orders execute automatically when price crosses the specified tick:
```solidity
function tryExecutingOrders(
    PoolKey calldata key,
    bool executeZeroForOne
) internal returns (bool tryMore, int24 newTick)
```

### 2. ERC-1155 Claim Tokens

Proportional redemption system:
- Token ID = unique order identifier
- Balance = amount of input tokens
- Claimable output calculated proportionally

### 3. Recursive Protection

Prevents infinite loops:
```solidity
if (sender == address(this)) return (this.afterSwap.selector, 0);
```

### 4. Dynamic Order Execution

Re-checks eligibility after each order execution:
```solidity
while (tryMore) {
    (tryMore, currentTick) = tryExecutingOrders(key, !params.zeroForOne);
}
```

---

## Project Structure

```
tests-homework/
├── src/
│   └── LimitOrder.sol              # Main hook implementation
├── test/
│   └── LimitOrder.t.sol            # Comprehensive test suite
├── script/
│   └── Deploy.s.sol                # Deployment script
├── lib/                            # Dependencies (v4-core, v4-periphery, etc.)
├── README.md                       # Project documentation
├── HOMEWORK_ASSIGNMENT.md          # This file
└── foundry.toml                    # Foundry configuration
```

---

## Learning Outcomes

By completing this homework, you should be able to:

1. **Understand Tick Mechanics**
   - How ticks represent price levels
   - How tick movements relate to price changes
   - How to track tick changes across swaps

2. **Implement Complex Hook Logic**
   - Use multiple hook permissions (afterInitialize, afterSwap)
   - Handle recursive execution scenarios
   - Manage state across multiple swaps

3. **Work with ERC-1155**
   - Mint and burn tokens programmatically
   - Calculate proportional distributions
   - Handle multiple token IDs

4. **Handle Edge Cases**
   - Prevent reentrancy
   - Handle partial fills
   - Validate order parameters

5. **Write Comprehensive Tests**
   - Test individual functions
   - Test integration scenarios
   - Test edge cases and failure modes

---

## Common Issues and Solutions

### Issue 1: BaseHook Import Error

**Problem**: Cannot find BaseHook.sol

**Solutions**:
- Check v4-periphery version
- Try both import paths: `src/utils/BaseHook.sol` or `src/base/hooks/BaseHook.sol`
- See class questions document for detailed explanation

### Issue 2: ERC1155InvalidReceiver Error

**Problem**: Tests fail when receiving ERC-1155 tokens

**Solution**:
```solidity
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract LimitOrderTest is Test, Deployers, ERC1155Holder {
    // ...
}
```

### Issue 3: Orders Not Executing

**Problem**: Orders placed but never execute

**Checklist**:
- Is afterSwap being called? (Check hook permissions)
- Is tick actually crossing the order tick?
- Is `lastTicks` being updated correctly?
- Are you checking the correct order direction (zeroForOne)?

### Issue 4: Recursive Execution

**Problem**: Stack overflow or unexpected behavior

**Solution**: Ensure sender check in afterSwap:
```solidity
if (sender == address(this)) return (this.afterSwap.selector, 0);
```

---

## Next Steps After Completion

1. **Optimize Gas Costs**
   - Profile gas usage with `forge test --gas-report`
   - Optimize storage layout
   - Consider batching operations

2. **Add Production Features**
   - Slippage protection for orders
   - Order expiration timestamps
   - Partial fill support
   - Native ETH support

3. **Deploy to Testnet**
   - Use deployment script
   - Verify on Basescan
   - Test with real swaps

4. **Prepare for Hackathon**
   - Study advanced hook patterns
   - Explore novel use cases
   - Build portfolio of hook implementations

---

## Resources

### Documentation
- [Uniswap v4 Docs](https://docs.uniswap.org/contracts/v4)
- [Hook Development Guide](https://docs.uniswap.org/contracts/v4/guides/hook-development)
- [ERC-1155 Standard](https://eips.ethereum.org/EIPS/eip-1155)

### Code References
- Study notes in `/week-4/study-notes/`
- Test examples in this directory
- Class questions and answers document

### Tools
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)

---

## Submission Checklist

Before submitting:

- [ ] All tests passing (`forge test`)
- [ ] Code compiles without warnings (`forge build`)
- [ ] Repository is public on GitHub
- [ ] README.md has clear documentation
- [ ] Professional code formatting
- [ ] No emojis in documentation (professional appearance)
- [ ] Quest form submitted with repo link

---

**Submission Deadline**: As per UHI schedule
**Questions**: Ask during office hours or workshop sessions

**Remember**: It's okay if your implementation isn't perfect! The goal is to learn and understand the concepts. Build, test, iterate, and don't hesitate to ask for help.

---

**Status**: COMPLETED
**Grade**: Self-assessed - All requirements met
**Repository**: Public and ready for review
