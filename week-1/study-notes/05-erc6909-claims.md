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
