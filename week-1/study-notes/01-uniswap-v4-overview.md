# Uniswap V4 Overview - The Big Picture

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## What is Uniswap V4?

**One-line**: Uniswap V4 is a decentralized exchange (DEX) that enables token swaps with customizable behavior through "hooks".

**Simple Explanation**:
Imagine a vending machine. Normally, you insert money, press a button, and receive a snack. That's like Uniswap V3 - straightforward swaps.

Now imagine a smart vending machine where you can add custom features:
- Discount for buying multiple items
- Save change for later purchases
- Alert notifications for purchases

That's Uniswap V4! Hooks are plugins that customize exchange behavior.

---

## Real-World Analogy: Market Evolution

```
┌─────────────────────────────────────────────────────────┐
│  UNISWAP V2 = Old-School Farmers Market                 │
│  • Each vendor (pool) operates separately                │
│  • Fixed prices, no customization                        │
│  • Independent stalls                                     │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  UNISWAP V3 = Modern Shopping Mall                       │
│  • Stores remain separate but organized                  │
│  • Vendors set "price ranges" (concentrated liquidity)   │
│  • Still expensive to establish new stores               │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  UNISWAP V4 = Amazon Warehouse                           │
│  • ONE massive warehouse (PoolManager)                   │
│  • All products centralized (singleton design)           │
│  • Custom rules per product (hooks)                      │
│  • Highly efficient operations (flash accounting)        │
└─────────────────────────────────────────────────────────┘
```

---

## Visual: Uniswap V4 Architecture

```
                    USER INITIATES TOKEN SWAP
                              |
                              v
                    ┌─────────────────┐
                    │  Swap Router    │ ← Periphery Contract
                    │  (Interface)    │    (User interaction)
                    └────────┬────────┘
                             |
                    [Unlock & Callback]
                             |
                             v
         ┌───────────────────────────────────────┐
         │      POOL MANAGER (Singleton)         │
         │  ═══════════════════════════════════  │
         │                                        │
         │  ┌──────┐  ┌──────┐  ┌──────┐        │
         │  │Pool 1│  │Pool 2│  │Pool 3│ ...    │
         │  │ETH/  │  │USDC/ │  │DAI/  │        │
         │  │USDC  │  │DAI   │  │WBTC  │        │
         │  └───┬──┘  └──┬───┘  └──┬───┘        │
         │      |         |         |             │
         │      └─────────┴─────────┘             │
         │              |                         │
