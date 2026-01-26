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

