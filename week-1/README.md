# Week 1: Foundation - Understanding Uniswap V4 Core

**Period**: January 20-22, 2026
**Focus**: Architecture, Hooks, and Price Mathematics

---

## Overview

This week marked my introduction to Uniswap V4's fundamental architecture and the mathematical primitives that power concentrated liquidity. Two intensive sessions covered the protocol's design philosophy and the precision mechanics required for on-chain price calculations.

```
WEEK 1 ARCHITECTURE
═══════════════════════════════════════

Day 1: System Design          Day 2: Price Mechanics
┌─────────────────┐           ┌─────────────────┐
│  Singleton      │           │  Ticks          │
│  Flash Account  │           │  Q64.96         │
│  Transient Stor │           │  sqrtPriceX96   │
│  Hooks System   │           │  Liquidity Math │
└─────────────────┘           └─────────────────┘
         │                             │
         └──────────┬──────────────────┘
                    ▼
            Complete Foundation
            for Hook Development
```

---

## Day 1: Technical Introduction (January 20, 2026)

### The Singleton Insight

The most significant architectural decision in V4 is the singleton pattern. Every pool exists within one `PoolManager` contract rather than as separate deployments.

```
V3 Model:              V4 Model:
┌────────┐             ┌──────────────────┐
│ Pool A │             │   PoolManager    │
└────────┘             │ ┌────┬────┬────┐ │
┌────────┐      →      │ │ A  │ B  │ C  │ │
│ Pool B │             │ └────┴────┴────┘ │
└────────┘             └──────────────────┘
┌────────┐
│ Pool C │             All pools = Internal calls
└────────┘             Cross-pool swaps = Cheap
```

**Key Takeaway**: Internal function calls are drastically cheaper than external calls. Multi-hop routing becomes economically viable.

### Flash Accounting

Instead of transferring tokens at every step, V4 tracks deltas throughout a transaction and settles once at the end.

```
TRADITIONAL:           FLASH ACCOUNTING:
Transfer → Transfer    Track delta → Track delta → Settle
Transfer → Transfer    Track delta → Track delta → Settle
   (8 transfers)              (2 transfers)
```

This pairs with the locking mechanism - the `PoolManager` locks at transaction start, accumulates all debits/credits, and unlocks only after settlement. The efficiency gain is substantial.

### Transient Storage (EIP-1153)

The protocol leverages `TSTORE` and `TLOAD` opcodes for temporary state that auto-erases after transaction completion.

**Cost Comparison**:
- `SSTORE`: 20,000 gas (permanent)
- `TSTORE`: 100 gas (transaction-scoped)

For tracking deltas during a transaction, transient storage is optimal - no need to zero out storage afterward.

### ERC-6909: Multi-Token Claims

Rather than deploying separate ERC-20 contracts for claim tokens, V4 uses ERC-6909 - a multi-token standard where token IDs differentiate balances within one contract.

```
Claim Token Structure:
┌─────────────────────────────┐
│  ERC-6909 Contract          │
│  ┌───────────────────────┐  │
│  │ Token ID: ETH-USDC    │  │
│  │ Token ID: WBTC-DAI    │  │
│  │ Token ID: LINK-USDT   │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

### Hook System Architecture

Hooks are contracts that plugin to pool lifecycle events. The clever part: function permissions are encoded in the hook's address itself via bitmap.

```
Hook Address (Last byte):
0x...789ABCDEF

Binary flags in address:
Bit 0: beforeInitialize
Bit 1: afterInitialize
Bit 2: beforeSwap
Bit 3: afterSwap
...

Need correct flags? Must mine the address.
```

**Implication**: Hook deployment requires computational work to find an address matching your permission needs. This was unexpected but makes validation gas-efficient.

---

## Day 2: Ticks and Price Mathematics (January 22, 2026)

### Discrete Price Points - Ticks

Concentrated liquidity requires price boundaries. Rather than continuous prices, V4 uses discrete ticks.

```
Price Spectrum:
─────────────────────────────────→
     Continuous (infinite points)

Tick Spectrum:
──┬───┬───┬───┬───┬───┬──→
  │   │   │   │   │   │
 -2  -1   0   1   2   3
     Discrete (specific points)
```

**Formula**: `price = 1.0001^tick`

Each tick represents a 0.01% price change. This granularity is sufficient for all practical trading pairs.

**Tick Spacing** varies by fee tier:
- 0.01% fee → spacing 1 (stable pairs)
- 0.30% fee → spacing 60 (standard pairs)
- 1.00% fee → spacing 200 (volatile pairs)

### Q64.96 Fixed-Point Numbers

Solidity has no floating-point support. Q64.96 solves this by representing decimals as scaled integers.

```
Q64.96 Structure:
┌──────────┬──────────────┐
│ 64 bits  │   96 bits    │
│ Integer  │  Fractional  │
└──────────┴──────────────┘
    Total: 160 bits

Encoding: value × 2^96
Decoding: value ÷ 2^96
```

**Example**: `1.5` becomes `1.5 × 2^96 = 118,842,243,771,396,506,690,315,925,504`

The precision (96 bits fractional) provides ~29 decimal places - more than sufficient for any token ratio.

**Critical Detail**: When multiplying two Q64.96 numbers, you must divide by 2^96 to restore correct scaling. Forgetting this is a common bug pattern.

### sqrtPriceX96 - Square Root Price

Rather than storing price `P`, V4 stores `√P` in Q64.96 format.

```
Conversion Flow:
Price (P)
   ↓ Square root
√P
   ↓ × 2^96
sqrtPriceX96
```

**Why square roots?**

Liquidity calculations simplify dramatically:
- Without √P: `L = Δx × Δy` (requires sqrt during calculation)
- With √P: `L = Δx × √P` (direct multiplication)

Gas savings compound across every swap and liquidity operation.

### Practical Application

Understanding these primitives is essential for hook development. Every hook interacts with:
- **Ticks**: Reading position ranges, setting limits
- **sqrtPriceX96**: Monitoring price changes, calculating slippage
- **Q64.96**: Any custom price logic or calculations

```
Hook Development Flow:
┌─────────────────────────┐
│ Read pool.slot0()       │ → sqrtPriceX96, tick
│ Convert to human price  │ → Understanding
│ Implement logic         │ → Decision making
│ Calculate limits        │ → Back to sqrtPriceX96
│ Execute action          │ → PoolManager call
└─────────────────────────┘
```

---

## Key Insights

**Architecture**:
1. Singleton design enables cheap multi-pool operations
2. Flash accounting + transient storage = minimal gas overhead
