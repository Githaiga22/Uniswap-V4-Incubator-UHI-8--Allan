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
   │  Reviews: "Works great!"     │
   └──────────────────────────────┘

Step 3: Make informed decision
        ↓
   High rating → Safe to use ✅
   Low rating  → Avoid! ❌
```

---

### 📈 Current Hook Market Stats (2026)

As of January 2026, HookRank shows:

```
Total Hooks Deployed:  24
Total TVL:            ~$325M+
Leading Hook:         Flaunch
  ├─ Launched:        2,135 tokens
  ├─ Volume:          $75.6M
  └─ Earnings:        51 ETH returned to creators
```

---

### 🛡️ Why HookRank Matters for YOU

**Security**: Not all hooks are created equal. Some might have bugs, be poorly optimized, or even be malicious!

**Risk Management**:
```
❌ Without HookRank:
  "This hook looks cool, let me put $10k in!"
  → Hook fails
  → You lose money

✅ With HookRank:
  "Let me check the rating first..."
  → Rating: 25/100, many failed transactions
  → "Nope, staying away!"
  → Money saved!
```

---

### 💡 What to Look For

When evaluating a hook on HookRank:

1. **Overall Rating > 70**: Generally safe
2. **Success Rate > 95%**: Reliable
3. **Transaction Volume**: Higher = more tested
4. **User Reviews**: Read the experiences
5. **Gas Costs**: Factor into your trading strategy

---

### 🔗 Related Resources

- **HookRank Documentation**: https://hookrank.gitbook.io/hookrank/
- **HookRank GitHub**: Check the project showcase
- **ETHGlobal Showcase**: https://ethglobal.com/showcase/hookrank-ym97n

---

## 🏦 Uniswap V4 PoolManager Contract

**Link**: https://etherscan.io/address/0x000000000004444c5dc75cb358380d2e3de08a90

**Contract Address**: `0x000000000004444c5dc75cb358380d2e3de08a90`

### 🎓 What is This Contract?

**One-line**: This is THE actual Uniswap V4 PoolManager contract deployed on Ethereum mainnet - the singleton contract that manages ALL V4 pools.

**Simple Explanation**:
Remember how we learned about the singleton design? This is it in real life! This is the actual contract address where all Uniswap V4 magic happens on Ethereum.

```
┌─────────────────────────────────────────┐
│  UNISWAP V4 POOL MANAGER                │
│  (The Brain of Uniswap V4)              │
