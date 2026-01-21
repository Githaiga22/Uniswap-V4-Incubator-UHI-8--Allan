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
