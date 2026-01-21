# Class Questions - Teacher's Answer Key

**Date**: January 20, 2026

---

## 🎯 Architecture & Design Questions

### 1. Singleton Design - Bug Risk
**Q**: "You mentioned all pools live in one PoolManager contract now. What happens if there's a bug in the PoolManager? Would that affect ALL pools, versus V3 where only one pool would be affected?"

**A**: Great question! You're absolutely right - this is a valid tradeoff. In V3, if one pool contract had a bug, only that specific pool was affected. In V4, a bug in the PoolManager *could* theoretically affect all pools.

However, there are several mitigations:

1. **Extensive auditing**: The PoolManager is audited by multiple top-tier firms because it's so critical
2. **Battle-tested code**: Most logic is delegated to well-tested libraries
3. **Immutability**: Core contracts are immutable once deployed, so no one can change them
4. **Bug bounty programs**: Million-dollar bug bounties incentivize white-hat hackers to find issues before launch

The Uniswap team believes the gas savings and flexibility benefits outweigh this risk, especially given the intense scrutiny the code receives.

---

### 2. Gas Savings for Simple Swaps
**Q**: "The gas savings from flash accounting sound amazing for multi-hop swaps. But for simple single swaps, is there actually a significant gas difference compared to V3? Or is the benefit mainly for complex trades?"

**A**: Excellent observation! You're right that the benefits are most dramatic for multi-hop swaps. For a simple single-hop swap (ETH → USDC), the gas savings from flash accounting alone are modest - maybe 10-15% compared to V3.

However, single swaps still benefit from:
- **Singleton architecture**: Cheaper pool interactions overall
- **Transient storage**: Reduces storage costs significantly
- **Optimized code**: Various small optimizations throughout

The real magic happens with:
- Multi-hop swaps (30-50% savings)
- Frequent traders using ERC-6909 claims (40-60% savings)
- Batched operations

Think of it this way: Even a small improvement across millions of transactions adds up to massive savings for the ecosystem!

---

### 3. Hook Limitations
**Q**: "Since hooks can add arbitrary code, is there a gas limit or complexity limit for what a hook can do? Like, could a hook theoretically make a pool too expensive to use?"

**A**: Yes, absolutely! This is a real concern. There's no explicit gas limit imposed by V4 itself - hooks are limited only by Ethereum's block gas limit (30 million gas).

This means:
- A poorly written hook could make swaps very expensive
- A malicious hook could intentionally make a pool unusable
- Complex hooks (like on-chain orderbooks) will naturally cost more gas

**The solution is market-driven**:
- Users will simply avoid expensive pools
- For popular token pairs, multiple pools will exist
- The cheapest/best pools will attract the most liquidity
- Routers will automatically find the most efficient path

Think of it like restaurants: A restaurant that charges $100 for a burger won't get customers, no matter how fancy their kitchen is!

---

## 🔧 Technical Implementation Questions

### 4. Hook Address Bitmap - False Signaling
**Q**: "The hook address bitmap system is clever, but what prevents someone from accidentally deploying a hook at an address that signals functions it doesn't actually implement? Would pools just fail when they try to call those functions?"

**A**: Great catch! Yes, exactly - if the address "lies" about what it implements, calls to unimplemented functions will fail and the transaction will revert.

Here's what happens:
1. Pool is initialized with a fake hook address
2. User tries to swap
3. PoolManager tries to call `beforeSwap` on the hook
4. Function doesn't exist → Transaction reverts
5. Pool becomes unusable

**Protection mechanisms**:
- In practice, you need to mine/generate the correct address (we'll learn this later)
- The deployment process ensures your address matches your implementation
- Testing will catch these issues before mainnet deployment
- Community verification of popular hooks

It's similar to having a phone number that claims to be a pizza place but isn't - when you call, you'll find out quickly it's wrong!

---

### 5. ERC-6909 Claims - Who Should Use?
**Q**: "For the ERC-6909 claim tokens - are these meant mainly for high-frequency traders, or would regular users also benefit from using them? I'm trying to understand when I'd want to keep tokens in the PoolManager versus just withdrawing them."

**A**: Fantastic question! Claims are **primarily** beneficial for high-frequency use cases:

**High benefit**:
- Market makers doing 100s of trades per day
- Arbitrage bots
- Traders doing multiple swaps in a session
- Liquidity providers frequently rebalancing

**Low benefit**:
- Someone who swaps once a month
- Buy-and-hold users
- Single one-off swaps

**Rule of thumb**: If you're doing 3+ operations in a short timeframe, claims save gas. Otherwise, regular tokens are fine.

Think of it like a coffee shop punch card: If you visit daily, it's worth signing up. If you visit once a year, don't bother!

---

### 6. Transient Storage - Transaction Failure
**Q**: "Since transient storage gets erased after each transaction, what happens if a transaction fails halfway through? Does the cleanup happen automatically, or do we need to handle that?"

**A**: Excellent question! The beautiful thing about transient storage is it's **automatically cleaned up** by the EVM itself, regardless of transaction success or failure.

```
Transaction starts  → Transient storage available
Transaction succeeds → Erased
Transaction reverts  → Also erased!
```

You don't need to do anything special. It's like writing on a whiteboard with automatic cleaning:
- End of class? Erased.
- Fire alarm mid-class? Still erased.
- Meteor hits the school? Okay, maybe not erased, but you get the point!

This is actually a HUGE benefit - no cleanup code needed, no gas spent on cleanup, no possibility of leftover dirty state.

---

## 🤔 Conceptual Understanding Questions

### 7. V3 vs V4 Evolution
**Q**: "What was the main bottleneck or pain point from V3 that V4 was specifically designed to solve? Was it purely gas costs, or were there other major issues?"
