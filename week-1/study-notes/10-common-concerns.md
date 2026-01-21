# Common Concerns About Uniswap V4

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## 🎓 Introduction

**One-line**: Addressing the three main worries people have about Uniswap V4: gas costs, liquidity fragmentation, and licensing.

**Simple Explanation**:
Whenever something new launches, people worry. It's natural! V4 introduces big changes, so let's address the common concerns head-on and understand why they might (or might not) be issues.

---

## ⛽ Concern #1: Gas Costs from Hooks

### 😰 The Worry
```
"Hooks add arbitrary code to pools.
Won't this make some pools SUPER expensive to use?
I might pay 10× more gas just because of a fancy hook!"
```

---

### 🎨 Visual: Gas Cost Spectrum

```
POOL GAS COSTS (from cheap to expensive)
═══════════════════════════════════════

No-Hook Pool
├─ Swap gas: 50,000
├─ Just basic AMM logic
└─ Same as V3
   💰 Cost: $5 on L1

Simple Hook Pool (e.g., dynamic fees)
├─ Swap gas: 65,000
├─ beforeSwap: 15,000 gas
├─ Basic price check
└─ Still reasonable
   💰 Cost: $6.50 on L1

Complex Hook Pool (e.g., on-chain orderbook)
├─ Swap gas: 200,000+
├─ beforeSwap: 50,000 gas
├─ afterSwap: 100,000 gas
├─ Lots of storage operations
└─ Expensive but offers unique features
   💰 Cost: $20 on L1
```

---

### 📊 The Reality

**Two Arguments Why This Isn't So Bad:**

#### 1. Market Forces Will Regulate Costs
```
Token Pair: ETH/USDC

Pool A: No hooks               → Cheap ✅
Pool B: Simple dynamic fees    → Medium
Pool C: Complex MEV protection → Expensive

Result:
├─ Regular users → Use Pool A
├─ Power traders → Use Pool C (worth the cost)
└─ Liquidity concentrates in best pools

Market solves the problem naturally!
```

#### 2. Layer 2 Makes Everything Cheap
```
GAS COSTS COMPARISON
═══════════════════

Ethereum L1:
├─ Simple swap: $5
├─ Complex hook: $20
└─ Difference: $15 (300% more!)

Arbitrum/Optimism (L2):
├─ Simple swap: $0.10
├─ Complex hook: $0.30
└─ Difference: $0.20 (300% more!)

On L2, even 300% more is still dirt cheap!
The absolute cost matters, not the percentage.
```

---

### 🌍 Real-World Analogy: Shipping Options

```
AMAZON SHIPPING
═══════════════

Standard Shipping (No-hook pool):
├─ Delivery: 5-7 days
├─ Cost: Free
└─ Most people use this ✅

Prime Shipping (Simple hook):
├─ Delivery: 2 days
├─ Cost: $5
└─ Worth it for some people

Same-Day Drone (Complex hook):
├─ Delivery: 4 hours
├─ Cost: $50
└─ Only for emergencies

Everyone has options!
The market provides what users need.
```
