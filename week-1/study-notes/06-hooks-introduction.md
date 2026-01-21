# Hooks Introduction - Custom Pool Superpowers

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## 🎓 What are Uniswap V4 Hooks?

**One-line**: Hooks are custom smart contracts you write that plug into pools to add special features and behaviors.

**Simple Explanation**:
Think of a pool as a smartphone. Out of the box, it makes calls and sends texts (basic swaps and liquidity).

**Hooks are like apps** you can install:
- Camera app = Add photo features
- Maps app = Add navigation
- Game app = Add entertainment

**Uniswap Hooks**:
- Dynamic fee hook = Change fees based on market conditions
- Limit order hook = Buy/sell at specific prices
- MEV protection hook = Prevent front-running
- TWAP oracle hook = Track average prices

---

## 🌍 Real-World Analogy: Restaurant Customization

### Uniswap V3: Basic Restaurant
```
┌────────────────────────────────┐
│   STANDARD RESTAURANT          │
├────────────────────────────────┤
│  • Fixed menu                  │
│  • Fixed prices                │
│  • No modifications allowed    │
│  • Same experience every time  │
│                                │
│  "This is the way it is!"      │
└────────────────────────────────┘

You get what you get!
```

### Uniswap V4: Customizable Restaurant (with Hooks!)
```
┌────────────────────────────────────────────────────┐
│   CUSTOMIZABLE RESTAURANT (Your Restaurant + Hooks)│
├────────────────────────────────────────────────────┤
│  Base Restaurant (Pool):                           │
│  • Serve food (do swaps)                           │
│  • Take orders (add liquidity)                     │
│                                                     │
│  Custom Add-ons (Hooks):                           │
│  🎉 Happy Hour Hook:                               │
│     → Prices drop 50% from 4-6pm                   │
│                                                     │
│  💎 Loyalty Program Hook:                          │
│     → Frequent customers get rewards               │
│                                                     │
│  🔒 VIP Section Hook:                              │
│     → Special features for members only            │
│                                                     │
│  ⏰ Reservation System Hook:                       │
│     → Pre-order your food (limit orders!)          │
└────────────────────────────────────────────────────┘

You design the experience!
```

---

## 🎨 Visual: Hooks Are Like React Hooks

If you've done web development, this concept might sound familiar!

### React Hooks (Web Development)
```javascript
function MyComponent() {
    // Hook into component lifecycle
    const [data, setData] = useState(null);

    // Hook: Run code AFTER component renders
    useEffect(() => {
        console.log("Component rendered!");
    }, []);

    // Hook: Run code BEFORE component updates
    useEffect(() => {
        console.log("About to update!");
    }, [data]);

    return <div>{data}</div>;
}
```

**React hooks let you "plug into" different points of a component's lifecycle.**

### Uniswap Hooks (Smart Contracts)
```solidity
contract MyHook {
    // Hook into pool lifecycle

    // Hook: Run code BEFORE a swap
    function beforeSwap(...) external {
        // Custom logic here
    }

    // Hook: Run code AFTER a swap
    function afterSwap(...) external {
        // Custom logic here
    }

    // Hook: Run code BEFORE adding liquidity
    function beforeAddLiquidity(...) external {
        // Custom logic here
    }
}
```

**Uniswap hooks let you "plug into" different points of a pool's operations.**

---

## 🎯 All Available Hook Functions

V4 gives you 14 different "plugin points":

```
┌─────────────────────────────────────────────────────┐
│  POOL LIFECYCLE HOOKS                               │
├─────────────────────────────────────────────────────┤
│                                                      │
│  INITIALIZATION (Pool Setup)                        │
│  ├─ beforeInitialize   → Before pool is created     │
│  └─ afterInitialize    → After pool is created      │
│                                                      │
│  SWAPS (Trading)                                    │
│  ├─ beforeSwap         → Before any swap            │
│  ├─ afterSwap          → After any swap             │
│  ├─ beforeSwapReturnDelta → Advanced swap control   │
│  └─ afterSwapReturnDelta  → Advanced swap control   │
│                                                      │
│  LIQUIDITY (Adding/Removing)                        │
│  ├─ beforeAddLiquidity       → Before adding LP     │
│  ├─ afterAddLiquidity        → After adding LP      │
│  ├─ beforeRemoveLiquidity    → Before removing LP   │
│  ├─ afterRemoveLiquidity     → After removing LP    │
│  ├─ afterAddLiquidityReturnDelta → Advanced LP     │
│  └─ afterRemoveLiquidityReturnDelta → Advanced LP  │
│                                                      │
│  DONATIONS (Tipping LPs)                            │
│  ├─ beforeDonate       → Before donation            │
│  └─ afterDonate        → After donation             │
└─────────────────────────────────────────────────────┘
```

**You don't need to implement ALL of them!** Pick only what you need.

---

## 💡 Hook Function Examples

### beforeSwap - Run Code Before a Swap
```solidity
// Example: Block swaps during weekends
function beforeSwap(...) external returns (bytes4) {
    if (isWeekend()) {
        revert("No trading on weekends!");
    }
    return this.beforeSwap.selector;
}
```

### afterSwap - Run Code After a Swap
```solidity
// Example: Reward the trader with loyalty points
function afterSwap(...) external returns (bytes4) {
    giveRewards(msg.sender, 100);
    return this.afterSwap.selector;
}
```

### beforeAddLiquidity - Run Code Before Adding Liquidity
```solidity
// Example: Only allow whitelisted LPs
function beforeAddLiquidity(...) external returns (bytes4) {
    require(isWhitelisted(msg.sender), "Not whitelisted!");
    return this.beforeAddLiquidity.selector;
}
```

---

## 🎨 Visual: Hook Flow in Action

```
USER INITIATES SWAP
        │
        ▼
┌───────────────────┐
│   beforeSwap()    │ ◄── Your custom code runs here!
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  ACTUAL SWAP      │ ◄── Core Uniswap logic
│  (Price calc,     │
│   balance update) │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│   afterSwap()     │ ◄── Your custom code runs here!
└────────┬──────────┘
         │
         ▼
  SWAP COMPLETE ✅
```

---

## 🌟 Real-World Hook Use Cases

### 1. Dynamic Fee Hook
```
Problem: Fixed fees don't adapt to market volatility

Hook Solution:
┌─────────────────────────────────────┐
│  beforeSwap():                      │
│  1. Check current market volatility │
│  2. If high volatility → 0.5% fee   │
│  3. If low volatility  → 0.1% fee   │
└─────────────────────────────────────┘

Benefit: Competitive fees that adapt!
```

### 2. Limit Order Hook
```
Problem: Can't buy/sell at specific prices on AMMs

Hook Solution:
┌─────────────────────────────────────┐
│  Users place limit orders           │
│                                     │
│  beforeSwap():                      │
│  1. Check if any limit orders       │
│     can be filled at current price  │
│  2. Fill those orders first         │
│  3. Then do the regular swap        │
└─────────────────────────────────────┘

Benefit: Limit orders on Uniswap!
```

### 3. MEV Protection Hook
```
Problem: Bots can sandwich attack your trades

Hook Solution:
┌─────────────────────────────────────┐
│  beforeSwap():                      │
│  1. Check if swap price deviates    │
│     too much from oracle price      │
│  2. If suspicious → Delay swap by   │
│     one block                       │
│  3. Prevents front-running          │
└─────────────────────────────────────┘

Benefit: Safer trading!
```

### 4. TWAP Oracle Hook
```
Problem: Need time-weighted average prices

Hook Solution:
┌─────────────────────────────────────┐
│  afterSwap():                       │
│  1. Record current price            │
│  2. Update running average          │
│  3. External contracts can read     │
│     the TWAP                        │
└─────────────────────────────────────┘

Benefit: On-chain price feed!
```

### 5. Loyalty Rewards Hook
```
Problem: No incentive for regular traders

Hook Solution:
┌─────────────────────────────────────┐
│  afterSwap():                       │
│  1. Track user's trading volume     │
│  2. Give points/NFTs to frequent    │
│     traders                         │
│  3. Points unlock benefits          │
└─────────────────────────────────────┘

Benefit: Gamified trading!
```

---

## 🎨 Visual: One Hook, Multiple Functions

You can implement ANY combination of hooks:

```
Example: Full-Featured Trading Pool

┌─────────────────────────────────────────────┐
│       MyAwesomeHook Contract                │
├─────────────────────────────────────────────┤
│                                              │
│  ✓ beforeSwap                               │
│    → Check if price is reasonable           │
│                                              │
│  ✓ afterSwap                                │
│    → Update TWAP oracle                     │
│    → Give loyalty points                    │
│                                              │
│  ✓ beforeAddLiquidity                       │
│    → Check if user is whitelisted           │
│                                              │
│  ✗ afterAddLiquidity     (not implemented)  │
│  ✗ beforeRemoveLiquidity (not implemented)  │
│  ✗ afterRemoveLiquidity  (not implemented)  │
│                                              │
└─────────────────────────────────────────────┘

You only implement what you need!
```

---

## 🔄 beforeX vs afterX Hooks

### When to use `before` hooks:
- **Validation**: Check if an operation should be allowed
- **Prerequisites**: Ensure conditions are met
- **Blocking**: Prevent operations under certain conditions

Example:
```solidity
function beforeSwap(...) {
    require(isNotPaused, "Trading paused!");
    require(userNotBlacklisted, "You're banned!");
}
```

### When to use `after` hooks:
- **Recording**: Log what happened
- **Side effects**: Trigger additional actions
- **Updates**: Update external state based on the operation

Example:
```solidity
function afterSwap(...) {
    recordSwapInDatabase();
    updateOraclePrice();
    giveRewardsToUser();
}
```

---

## 🎯 Donations - The Special Case

**Donation** = Directly tipping liquidity providers

```
Why donations exist:

Normal fees → Split between LPs + Protocol
Donations   → Go 100% to LPs

Use case for hooks:
┌────────────────────────────────────────┐
│  Custom value distribution:            │
│                                        │
│  afterSwap():                          │
│    → Collect some fee                  │
│    → donate() to reward LPs           │
│                                        │
│  Result: Hook can create custom        │
│  reward mechanisms for LPs!            │
└────────────────────────────────────────┘
```

---

## ⚠️ Important Hook Rules

### 1. Hooks are OPTIONAL
- Pools can have NO hook (just like V3)
- Pools with no hooks are cheaper to use

### 2. Hooks are SET AT INITIALIZATION
- Once a pool is created with a hook, it's permanent
- Can't change the hook later

### 3. Hooks CAN'T be trusted blindly
- Anyone can write any hook
- LPs and traders should verify hook code before using

### 4. Hooks ADD gas costs
- More code = more gas
- Complex hooks = expensive trades
- Simple hooks = minimal overhead

---

## 🔗 Resources & Citations

1. **Atrium Academy - V4 Hooks**
   https://learn.atrium.academy/course/4b6c25df-f4c8-4b92-ab38-a930284d237e/technical-introduction/v4-hooks

2. **Uniswap V4 Hooks Library**
   https://github.com/Uniswap/v4-core/blob/main/src/libraries/Hooks.sol

3. **Hook Examples Repository**
   https://github.com/Uniswap/v4-periphery

4. **React Hooks Documentation (for comparison)**
   https://react.dev/reference/react

---

## ✅ Quick Self-Check

1. **What are hooks in Uniswap V4?**
   <details>
   <summary>Answer</summary>
   Custom smart contracts that plug into specific points in a pool's lifecycle to add custom behavior and features.
   </details>

2. **Do you have to implement all 14 hook functions?**
   <details>
   <summary>Answer</summary>
   No! You only implement the ones you need. The rest can be left unimplemented.
   </details>

3. **What's the difference between beforeSwap and afterSwap?**
   <details>
   <summary>Answer</summary>
   beforeSwap runs BEFORE the swap happens (good for validation/blocking), afterSwap runs AFTER (good for recording/side effects).
   </details>

4. **Can you change a pool's hook after it's created?**
   <details>
   <summary>Answer</summary>
   No, the hook is set when the pool is initialized and cannot be changed.
   </details>

5. **Give one real-world use case for hooks.**
   <details>
   <summary>Answer</summary>
   Dynamic fees that adjust based on market volatility, limit orders, MEV protection, loyalty rewards, TWAP oracles, etc.
   </details>

---

**Previous**: [ERC-6909 Claims](./05-erc6909-claims.md)
**Next**: [Hook Mechanics (Technical Details)](./07-hook-mechanics.md)
