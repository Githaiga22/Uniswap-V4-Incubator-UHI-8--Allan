# Important Links & Resources - Week 1

**Date**: January 20, 2026

---

## 🔗 HookRank.io - Hook Analytics Platform

**Link**: https://hookrank.io/

### 🎓 What is HookRank?

**One-line**: A ratings and analytics platform that helps you evaluate and compare Uniswap V4 hooks based on performance, safety, and usage metrics.

**Simple Explanation**:
Think of HookRank like **Yelp for Uniswap hooks**. Just like you'd check restaurant reviews before eating somewhere new, you should check hook reviews before putting your money in a pool with hooks!

```
┌────────────────────────────────────────┐
│  HOOKRANK.IO = Hook Review Platform    │
├────────────────────────────────────────┤
│                                        │
│  For each hook, you can see:          │
│  ⭐ Overall Rating (0-100)            │
│  📊 Transaction Volume                 │
│  ✅ Success Rate                       │
│  ⛽ Gas Costs                          │
│  💬 User Reviews                       │
│  🔐 Security Info                      │
└────────────────────────────────────────┘
```

---

### 📊 Hook Rating System

HookRank uses a comprehensive scoring system:

```
Overall Hook Rating =
    W1 × Transaction Volume Score (TVS) +
    W2 × Success Rate Score (SRS) +
    W3 × Gas Spending Score (GSS)

Where W1, W2, W3 are weights that sum to 1

Example:
Hook A: 85/100 ⭐⭐⭐⭐
├─ TVS: 90 (high volume)
├─ SRS: 95 (rarely fails)
└─ GSS: 70 (moderate gas costs)

Hook B: 45/100 ⭐⭐
├─ TVS: 30 (low volume)
├─ SRS: 50 (fails often!)
└─ GSS: 55 (expensive gas)

Verdict: Hook A is safer!
```

---

### 🎨 Visual: How to Use HookRank

```
BEFORE PROVIDING LIQUIDITY OR TRADING
═════════════════════════════════════

Step 1: Find the pool you're interested in
        ↓
   ┌─────────────────────┐
   │  ETH/USDC Pool      │
   │  Hook: 0xABC...123  │
   └─────────────────────┘

Step 2: Look up hook on HookRank.io
        ↓
   ┌──────────────────────────────┐
   │  Hook 0xABC...123            │
   │  Rating: 78/100 ⭐⭐⭐⭐     │
   │  Volume: $5M                 │
   │  Success: 98%                │
   │  Gas: Moderate               │
