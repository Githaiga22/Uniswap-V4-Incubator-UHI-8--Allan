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
  Total: ~10,000 gas

Transaction 2: Swap USDC Claims for DAI Claims
  1. Burn 1000 USDC claim tokens       (5,000 gas)
  2. Calculate swap
  3. Mint 1000 DAI claim tokens        (5,000 gas)
  Total: ~10,000 gas

Transaction 3: Swap DAI Claims for ETH Claims
  1. Burn 1000 DAI claim tokens        (5,000 gas)
  2. Calculate swap
  3. Mint 1 ETH claim tokens           (5,000 gas)
  Total: ~10,000 gas

Final: Withdraw ETH
  1. Burn ETH claim tokens             (5,000 gas)
  2. Transfer ETH to user              (50,000 gas)
  Total: ~55,000 gas

═══════════════════════════════════════
GRAND TOTAL: ~140,000 gas

SAVINGS: 53% cheaper! 🎉
```

---

## 🎨 Visual: Claim Token Flow

```
STEP 1: DEPOSIT & GET CLAIMS
═══════════════════════════════

  ┌──────────┐         1000 USDC          ┌──────────────┐
  │  TRADER  │ ─────────────────────────→ │ POOL MANAGER │
  │          │                             │              │
  │          │ ←───────────────────────── │              │
  └──────────┘   1000 USDC Claim Tokens   └──────────────┘


STEP 2: TRADE USING CLAIMS (Multiple Times)
══════════════════════════════════════════

  Swap 1: USDC Claims → DAI Claims
  ┌──────────┐                             ┌──────────────┐
  │  TRADER  │  Burn 500 USDC Claims       │ POOL MANAGER │
  │          │ ─────────────────────────→  │              │
  │          │                             │  [Math only] │
  │          │  Mint 500 DAI Claims        │              │
  │          │ ←─────────────────────────  │              │
  └──────────┘                             └──────────────┘

  Swap 2: DAI Claims → ETH Claims
  ┌──────────┐                             ┌──────────────┐
  │  TRADER  │  Burn 500 DAI Claims        │ POOL MANAGER │
  │          │ ─────────────────────────→  │              │
  │          │                             │  [Math only] │
  │          │  Mint 0.5 ETH Claims        │              │
  │          │ ←─────────────────────────  │              │
  └──────────┘                             └──────────────┘


STEP 3: WITHDRAW REAL TOKENS
═══════════════════════════════

  ┌──────────┐    Burn 0.5 ETH Claims     ┌──────────────┐
  │  TRADER  │ ─────────────────────────→ │ POOL MANAGER │
  │          │                             │              │
  │          │ ←───────────────────────── │              │
  └──────────┘       0.5 Real ETH         └──────────────┘
```

---

## 🔑 Why Minting/Burning is Cheaper

### ERC-20 Transfer (External Contract)
```
Steps involved:
1. Call external contract              (2,100 gas)
2. Check sender has balance            (2,100 gas)
3. Check recipient not blacklisted     (varies, could be 20,000+)
4. Update sender balance               (20,000 gas)
5. Update recipient balance            (20,000 gas)
6. Emit Transfer event                 (1,500 gas)
───────────────────────────────────────
TOTAL: ~45,000+ gas (minimum)

Note: Custom logic (like USDC blacklist) adds MORE gas!
```

### ERC-6909 Mint/Burn (Internal)
```
Steps involved:
1. Update balance mapping              (5,000 gas)
2. Emit event                          (1,500 gas)
───────────────────────────────────────
TOTAL: ~6,500 gas

No external calls, no custom logic!
Constant gas cost regardless of token!
```

---

## 📊 Who Should Use Claims?

### ✅ Great for Claims:
```
High-Frequency Traders:
├─ Do many swaps in short time
├─ Want to minimize gas costs
└─ Can deposit once, trade many times, withdraw once

Market Makers:
├─ Constantly providing liquidity
├─ Moving in and out of positions
└─ Claims reduce friction

Bots:
├─ Automated trading strategies
├─ Lots of small trades
└─ Gas efficiency is crucial
```

### ❌ Not Necessary for Claims:
```
Casual Traders:
├─ Do a swap once a month
├─ Don't benefit from claim system
└─ Just use regular tokens

One-Time Swappers:
├─ Swap once and leave
├─ Deposit + withdraw fees negate benefits
└─ Regular swaps are fine
```

---

## 💻 ERC-6909 vs ERC-1155

You might have heard of ERC-1155 (used for NFTs). ERC-6909 is similar but simpler:

| Feature | ERC-1155 | ERC-6909 |
|---------|----------|----------|
| **Purpose** | NFTs + Semi-Fungible | Fungible tokens only |
| **Complexity** | High | Low |
| **Gas Cost** | Higher | Lower |
| **Batch Transfers** | Yes | Yes |
| **Use Case** | Gaming, NFTs | DeFi, Trading |

**ERC-6909 = Simplified ERC-1155 optimized for DeFi**

---

## 🎨 Visual: The Full Picture

```
                    UNISWAP V4 ECOSYSTEM
    ┌─────────────────────────────────────────────────┐
    │                                                  │
    │  Regular Users                High-Freq Traders │
    │       │                              │          │
    │       v                              v          │
    │  ┌──────────┐                  ┌──────────┐    │
    │  │ Use Real │                  │Use Claims│    │
    │  │ Tokens   │                  │ Tokens   │    │
    │  └────┬─────┘                  └─────┬────┘    │
    │       │                              │          │
    │       └──────────────┬───────────────┘          │
    │                      │                          │
    │                      v                          │
    │         ┌─────────────────────────┐             │
    │         │    POOL MANAGER         │             │
    │         │                         │             │
    │         │  • Handles both!        │             │
    │         │  • You choose which     │             │
    │         │    works best for you   │             │
    │         └─────────────────────────┘             │
    │                                                  │
    └─────────────────────────────────────────────────┘
```

---

## 🔗 Resources & Citations

1. **ERC-6909 Specification**
   https://eips.ethereum.org/EIPS/eip-6909

2. **Atrium Academy - ERC-6909 Claims**
   https://learn.atrium.academy/course/4b6c25df-f4c8-4b92-ab38-a930284d237e/technical-introduction/v4-architecture

3. **Uniswap V4 Claims Implementation**
   https://github.com/Uniswap/v4-core/blob/main/src/ERC6909Claims.sol

4. **ERC-1155 vs ERC-6909 Comparison**
   https://ethereum.org/en/developers/docs/standards/tokens/

---

## ✅ Quick Self-Check

1. **What are claim tokens?**
   <details>
   <summary>Answer</summary>
   ERC-6909 tokens that represent your deposited assets in the PoolManager. Like a receipt or IOU for your real tokens.
   </details>

2. **Why are claims cheaper than transferring real tokens?**
   <details>
   <summary>Answer</summary>
   Minting/burning claim tokens happens inside the PoolManager (internal operations), while transferring real tokens requires external contract calls which are more expensive.
   </details>

3. **Who benefits most from using claims?**
   <details>
   <summary>Answer</summary>
   High-frequency traders, market makers, and bots who do many trades in a short time period.
   </details>

4. **Do you HAVE to use claims to trade on V4?**
   <details>
   <summary>Answer</summary>
   No! You can still trade using regular tokens. Claims are optional for users who want extra gas efficiency.
   </details>

5. **What's the difference between ERC-6909 and ERC-1155?**
   <details>
   <summary>Answer</summary>
   ERC-6909 is a simplified version focused on fungible tokens for DeFi, while ERC-1155 is more complex and designed for NFTs and gaming.
   </details>

---

**Previous**: [Transient Storage](./04-transient-storage.md)
**Next**: [Hooks Introduction](./06-hooks-introduction.md)
