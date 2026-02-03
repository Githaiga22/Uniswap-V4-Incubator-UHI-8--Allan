# Internal Swap Pool - Custom Pricing Curve Hook

**Author**: Allan Robinson
**Project**: Uniswap V4 Hooks Incubator - Week 3 Homework
**Date**: February 3, 2026

## Overview

This is a Custom Pricing Curve Hook (Return Delta Hook / NoOp Hook) that implements an internal swap pool for Uniswap V4. The hook solves the problem of unwanted selling pressure from fee distributions in token launchpad scenarios.

## Problem Statement

In traditional Uniswap pools, when users trade:
- Buying TOKEN with ETH → Fees collected in TOKEN
- Selling TOKEN for ETH → Fees collected in ETH

LPs earn fees in BOTH tokens. To realize profits, LPs must sell TOKEN for ETH, creating downward price pressure that hurts token holders.

## Solution

This hook ensures **all fees are distributed in ETH** by:

1. **Internal Orderbook**: Maintains internal TOKEN reserves from fees
2. **Smart Routing**: Fills TOKEN→ETH swaps from internal reserves first
3. **Zero Pressure**: Converts TOKEN fees to ETH without hitting the main pool
4. **LP Benefits**: LPs receive only ETH fees via `donate()`

## How It Works

### For ETH → TOKEN Swaps (Buying)

```
User: Buy TOKEN with 1 ETH
│
├─ beforeSwap: No internal action
├─ Core Swap: Uniswap AMM executes normally
└─ afterSwap:
   ├─ Capture 1% fee = 1 TOKEN
   └─ Store internally for future conversion
```

### For TOKEN → ETH Swaps (Selling)

```
User: Sell 50 TOKEN for ETH
│
├─ beforeSwap:
│  ├─ Hook has 1 TOKEN in reserves
│  ├─ Fill partially: Take 1 TOKEN, give 0.01 ETH
│  └─ Return BeforeSwapDelta to reduce amountToSwap
│
├─ Core Swap: Uniswap only swaps remaining 49 TOKEN
│
└─ afterSwap:
   ├─ Capture 1% fee from output
   └─ Distribute accumulated ETH fees to LPs
```

**Result**: TOKEN fees converted to ETH without pool price impact!

## Key Features

✅ **Single-Token Fee Distribution**: All LP fees in ETH
✅ **Reduced Price Impact**: Internal fills don't affect pool price
✅ **Gas Efficient**: Uses current pool price, no AMM computation
✅ **Fair Launch Friendly**: Perfect for token launchpads
✅ **Trustless**: All logic on-chain, atomic execution

## Technical Implementation

### Hook Permissions

- `beforeSwap` + `beforeSwapReturnDelta`: Fill swaps from internal pool
- `afterSwap` + `afterSwapReturnDelta`: Capture fees and distribute

### Core Functions

1. **beforeSwap**: Attempts to fill TOKEN→ETH swaps from internal reserves
2. **afterSwap**: Captures 1% fee from all swaps
3. **_distributeFees**: Donates accumulated ETH fees to LPs
4. **_handleExactInput**: Processes exact input swaps
5. **_handleExactOutput**: Processes exact output swaps

### Mathematics

Uses Uniswap's `SwapMath.computeSwapStep()` to calculate fair prices:

```solidity
(, ethOut, tokenIn, ) = SwapMath.computeSwapStep({
    sqrtPriceCurrentX96: sqrtPriceX96,
    sqrtPriceTargetX96: params.sqrtPriceLimitX96,
    liquidity: poolManager.getLiquidity(poolId),
    amountRemaining: int256(amount),
    feePips: 0  // No fee for internal swaps
});
```

## Project Structure

```
Internal-Swap-Pool/
├── src/
│   └── InternalSwapPool.sol    # Main hook implementation
├── test/
│   └── (tests to be added)
├── script/
│   └── (deployment scripts)
├── foundry.toml                 # Foundry configuration
├── remappings.txt               # Import remappings
└── README.md                    # This file
```

## Installation

```bash
# Install dependencies
forge install

# Build
forge build

# Test
forge test

# Test with gas reporting
forge test --gas-report
```

## Dependencies

- `@uniswap/v4-core`: Uniswap V4 core contracts
- `v4-periphery`: Uniswap V4 periphery contracts
- `forge-std`: Foundry standard library

## Configuration

`foundry.toml`:
- Solidity version: 0.8.26
- EVM version: Cancun
- Optimizer: Enabled (1M runs)
- Via IR: true
- FFI: true

## Usage

### Deployment

1. Deploy hook with proper address (use HookMiner for CREATE2)
2. Initialize pool with dynamic fees enabled
3. Hook will automatically manage fees and distributions

### Integration

```solidity
// Pool must have dynamic fees
PoolKey memory key = PoolKey({
    currency0: WETH,
    currency1: TOKEN,
    fee: FeeLibrary.DYNAMIC_FEE_FLAG,
    tickSpacing: 60,
    hooks: IHooks(hookAddress)
});

// Initialize pool
poolManager.initialize(key, initialPrice);
```

## Testing Strategy

Tests should cover:
- ✅ Basic swap functionality
- ✅ Internal swap pool filling
- ✅ Fee capture and distribution
- ✅ Both exact input and exact output swaps
- ✅ Edge cases (zero reserves, large amounts)
- ✅ Gas benchmarks

## Future Improvements

1. **Pool Validation**: Verify currency0 is ETH in `beforeInitialize`
2. **Position Manager**: Use concentrated liquidity instead of flat reserves
3. **Multi-Tier Fees**: Different fee rates based on swap size
4. **Whitelist**: Fee exemptions for certain addresses
5. **Emergency Pause**: Admin control for emergency situations

## Security Considerations

- Uses CEI (Checks-Effects-Interactions) pattern
- All state updates before external calls
- Proper delta accounting with `sync()`, `take()`, `settle()`
- No reentrancy vulnerabilities
- Fair pricing using SwapMath library

## License

MIT

## References

- [Uniswap V4 Documentation](https://docs.uniswap.org/contracts/v4/)
- [Return Delta Hooks](https://docs.uniswap.org/contracts/v4/concepts/hooks)
- [Original Implementation by Haardik](https://github.com/haardikk21/csmm-noop-hook)

---

**Built for Uniswap V4 Hooks Incubator**
Atrium Academy - Week 3 - February 2026
