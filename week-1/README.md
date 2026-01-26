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
