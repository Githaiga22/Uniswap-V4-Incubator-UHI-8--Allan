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

**A**: Great question! While gas costs were a big factor, V4 was primarily driven by **lack of customization**. Let me explain:

**V3 pain points**:
1. **No customization**: Want dynamic fees? Too bad. Want limit orders? Can't do it.
2. **High gas costs**: Especially for multi-hop swaps
3. **Governance battles**: Every feature needs DAO approval
4. **Slow innovation**: Takes forever to add new features

**V4 solution**:
- **Hooks = permissionless innovation**: Anyone can build custom features
- **Gas efficiency**: Singleton + flash accounting as enablers
- **No governance bottleneck**: Build without asking permission

Think of it like iPhone vs Android:
- V3 = iPhone: Polished but limited
- V4 = Android: Customizable, open ecosystem

The goal wasn't just "cheaper V3" - it was "enable infinite experiments we never imagined"!

---

### 8. Hook Composability
**Q**: "Can multiple hooks work together on the same pool? For example, could one hook handle dynamic fees while another handles MEV protection? Or is it one hook per pool?"

**A**: Excellent question! It's **one hook contract per pool**, BUT - and this is important - that one hook can do multiple things!

```
❌ Can't do this:
Pool → Hook 1 (dynamic fees)
    → Hook 2 (MEV protection)
    → Hook 3 (rewards)

✅ Can do this:
Pool → MegaHook (does all three!)
       ├─ Dynamic fees logic
       ├─ MEV protection logic
       └─ Rewards logic
```

So you need to combine your features into ONE hook contract. Think of it like:
- **Not allowed**: Multiple apps running on your phone at once for the same task
- **Allowed**: One app that has multiple features built in

Later in the course, we'll see patterns for composing hook functionality inside a single contract!

---

### 9. Liquidity Fragmentation
**Q**: "With potentially many pools for the same token pair (different hooks, fees, etc.), how do routers decide which pool to use for a swap? Is there a recommended default pool concept?"

**A**: This is THE big question everyone asks! Here's how it works in practice:

**Router decision process**:
1. Enumerate all ETH/USDC pools
2. For each pool:
   - Simulate the swap
   - Calculate output amount (accounting for fees, gas, etc.)
   - Score the route
3. Choose the best one

**In practice**:
- For major pairs, 2-3 pools usually dominate
- Most liquidity concentrates in the best pools
- Aggregators (like Uniswap X) handle this automatically
- Users don't need to think about it

**Analogy**: Multiple routes from home to work:
- Highway (fast, expensive toll) = High-gas fancy hook pool
- Side roads (slow, free) = No-hook pool
- Express lane (fast, cheap) = Optimized hook pool

Your GPS (router) picks the best route automatically!

We saw this same concern with V3 (multiple fee tiers), and it turned out fine. Market forces are powerful!

---

## 💰 Economic & Market Questions

### 10. Hook Economics
**Q**: "Who pays for the extra gas cost if a hook adds expensive operations? The trader or the LP? And can hook creators charge fees for using their hooks?"

**A**: Great economic thinking! Let's break this down:

**Who pays gas?**
- **Trader always pays** the gas for the entire transaction
- This includes hook execution
- LPs don't pay gas for swaps (they pay gas to add/remove liquidity)

**Example**:
```
Swap in normal pool:      50,000 gas
Swap with complex hook:  150,000 gas
                         ───────────
Trader pays:            +100,000 gas
```

**Can hooks charge fees?**
YES! Several ways:
1. **Protocol fees**: Hook takes a cut of swap fees
2. **Licensing fees**: Hook charges per use
3. **LP fees**: Hook distributes extra rewards to LPs, funded by traders
4. **NFT requirement**: Must hold NFT to use pool
5. **Token gating**: Must stake HOOK tokens

Think of it like toll roads:
- Base pool = Free highway
- Hook = Toll road with extra features
- Traders choose if the features are worth the cost!

---

### 11. Dynamic Fees
**Q**: "For hooks that implement dynamic fees, how quickly can fees adjust? Can they change mid-swap, or are they locked in when the swap starts?"

**A**: Excellent edge case question! Here's how it works:

**Fee is locked at the START of the swap**:
```
1. beforeSwap() is called
   → Fee is calculated here (e.g., 0.3%)
2. Swap happens with that fee
3. afterSwap() is called
   → Fee cannot change retroactively
```

**Why this matters**:
- Prevents fee manipulation attacks
- Gives traders certainty
- Allows for slippage protection

**However**, between transactions, fees can change as rapidly as the hook wants:
