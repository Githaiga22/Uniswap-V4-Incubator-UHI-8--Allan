# ERC-6909 Claims - Virtual Token IOUs

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## 🎓 What is ERC-6909?

**One-line**: ERC-6909 is a token standard that lets ONE contract manage multiple different token types, like a universal wallet.

**One-line for Claims**: Claim tokens are like "receipts" that prove you deposited tokens into the PoolManager, letting you trade without constantly moving tokens in and out.

**Simple Explanation**:
Imagine you go to an arcade:

**Old way (Regular tokens)**:
- Bring your own quarters
- Every time you play a game, put quarters in
- When you win tickets, take them out
- Next game? Put more quarters in again
- Constant in-and-out = annoying and slow

**New way (Claim tokens)**:
- Deposit $20 at the counter
- Get an arcade card (your "claim")
- Swipe card to play games (no physical money needed)
- Card balance updates automatically
- When done, cash out remaining balance
- Much faster and easier!

---

## 🌍 Real-World Analogy: Casino Chips vs Cash

### Using Real Money (Regular ERC-20 Tokens)
```
You at a Casino:

Game 1 - Poker:
  Pull out wallet → Count cash → Place bet
  Win money → Receive cash → Put in wallet

Game 2 - Blackjack:
  Pull out wallet → Count cash → Place bet
  Win money → Receive cash → Put in wallet

Game 3 - Roulette:
  Pull out wallet → Count cash → Place bet
  Lose money → Sad face

Problems:
❌ Constantly pulling out wallet (gas fees)
❌ Counting exact change every time (gas fees)
❌ Slow and cumbersome
```

### Using Casino Chips (ERC-6909 Claims)
```
You at a Casino:

At entrance:
  Exchange $1000 cash → Get $1000 in chips

Game 1 - Poker:
  Place chips → Win chips

Game 2 - Blackjack:
  Place chips → Win chips

Game 3 - Roulette:
  Place chips → Lose chips

At exit:
  Exchange remaining chips → Get cash back

Benefits:
✅ One exchange at entrance (one gas fee)
✅ Fast gameplay (internal accounting)
✅ One exchange at exit (one gas fee)
```

---

## 🎨 Visual: ERC-20 vs ERC-6909

### Traditional ERC-20 (Each token = separate contract)
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  ETH Token  │    │ USDC Token  │    │  DAI Token  │
│  Contract   │    │  Contract   │    │  Contract   │
├─────────────┤    ├─────────────┤    ├─────────────┤
│ balanceOf() │    │ balanceOf() │    │ balanceOf() │
│ transfer()  │    │ transfer()  │    │ transfer()  │
└─────────────┘    └─────────────┘    └─────────────┘
      │                   │                   │
      └───────────────────┴───────────────────┘
                          │
                    External Calls
                  (Expensive! ❌)
```

### ERC-6909 (One contract manages ALL tokens)
```
┌─────────────────────────────────────────────────────┐
│          POOL MANAGER (ERC-6909)                    │
├─────────────────────────────────────────────────────┤
│                                                      │
│  balances[user][ETH] = 100                          │
│  balances[user][USDC] = 5000                        │
│  balances[user][DAI] = 2000                         │
│  balances[user][WBTC] = 0.5                         │
│                                                      │
│  All managed in ONE contract!                       │
│  Internal accounting = Cheap! ✅                     │
└─────────────────────────────────────────────────────┘
```

---

## 💡 How Claims Work: Step-by-Step

### Scenario: High-Frequency Trader Doing Multiple Swaps

#### Without Claims (Old Way)
```
Transaction 1: Swap ETH for USDC
  1. Transfer 1 ETH to PoolManager     (50,000 gas)
  2. Calculate swap
  3. Transfer 1000 USDC to user        (50,000 gas)
  Total: ~100,000 gas

Transaction 2: Swap USDC for DAI
  1. Transfer 1000 USDC to PoolManager (50,000 gas)
  2. Calculate swap
  3. Transfer 1000 DAI to user         (50,000 gas)
  Total: ~100,000 gas

Transaction 3: Swap DAI for ETH
  1. Transfer 1000 DAI to PoolManager  (50,000 gas)
  2. Calculate swap
  3. Transfer 1 ETH to user            (50,000 gas)
  Total: ~100,000 gas

═══════════════════════════════════════
GRAND TOTAL: ~300,000 gas
```

#### With Claims (New Way)
```
One-Time Setup: Deposit ETH
  1. Transfer 10 ETH to PoolManager    (50,000 gas)
  2. Mint 10 ETH claim tokens          (5,000 gas)
  Total: ~55,000 gas

Transaction 1: Swap ETH Claims for USDC Claims
  1. Burn 1 ETH claim token            (5,000 gas)
  2. Calculate swap
  3. Mint 1000 USDC claim tokens       (5,000 gas)
