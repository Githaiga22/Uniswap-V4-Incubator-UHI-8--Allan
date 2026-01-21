# Singleton Design - One Contract to Rule Them All

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## 🎓 What is the Singleton Design?

**One-line**: Instead of creating a new contract for each trading pool, V4 puts ALL pools inside ONE giant contract called the PoolManager.

**Simple Explanation**:
Think about a library. In the old system (V3), every book genre had its own separate building:
- Science fiction → Building A
- Mystery → Building B
- Romance → Building C

To read books from different genres, you'd have to walk between buildings (expensive!).

In the new system (V4), ALL books are in ONE massive library (PoolManager). You can grab a sci-fi book, a mystery, and a romance all in one trip. Much more efficient!

---

## 🌍 Real-World Analogy: Restaurant Evolution

### Uniswap V3: Food Truck Park
```
┌─────────┐  ┌─────────┐  ┌─────────┐
│  Taco   │  │  Pizza  │  │  Burger │
│  Truck  │  │  Truck  │  │  Truck  │
│  🌮     │  │  🍕     │  │  🍔     │
└─────────┘  └─────────┘  └─────────┘

Want tacos AND pizza?
→ Walk to Taco Truck (gas fee)
→ Walk to Pizza Truck (gas fee)
→ Each truck = separate business (expensive to set up)
```

### Uniswap V4: Food Court (Singleton)
```
┌─────────────────────────────────────────┐
│         FOOD COURT MANAGER              │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐   │
│  │ 🌮  │  │ 🍕  │  │ 🍔  │  │ 🍜  │   │
│  │Taco │  │Pizza│  │Brgr │  │Ramen│   │
│  └─────┘  └─────┘  └─────┘  └─────┘   │
│                                         │
│  All vendors in ONE location!           │
│  One payment counter!                   │
│  Shared infrastructure!                 │
└─────────────────────────────────────────┘

Want tacos AND pizza?
→ Walk to one counter, order both (one gas fee)
→ All operations share the same building (cheaper)
```

---

## 🎨 Visual: V3 vs V4 Architecture

### Uniswap V3 Architecture
```
                    Factory Contract
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        v                 v                 v
   ┌─────────┐       ┌─────────┐       ┌─────────┐
   │ Pool 1  │       │ Pool 2  │       │ Pool 3  │
   │ Contract│       │ Contract│       │ Contract│
   ├─────────┤       ├─────────┤       ├─────────┤
   │ ETH/USDC│       │USDC/DAI │       │ DAI/WBTC│
   │ State   │       │ State   │       │ State   │
   │ Logic   │       │ Logic   │       │ Logic   │
   └─────────┘       └─────────┘       └─────────┘

   Each pool = NEW contract deployment
   External calls between pools = EXPENSIVE
```

### Uniswap V4 Architecture (Singleton)
```
              ┌────────────────────────────────┐
              │      POOL MANAGER              │
              │      (ONE Contract)            │
              ├────────────────────────────────┤
              │                                │
              │  Pool Registry (Mapping):      │
              │  ┌──────────────────────────┐  │
              │  │ PoolId → Pool.State      │  │
              │  ├──────────────────────────┤  │
              │  │ 0x01 → ETH/USDC Pool     │  │
              │  │ 0x02 → USDC/DAI Pool     │  │
              │  │ 0x03 → DAI/WBTC Pool     │  │
              │  │ 0x04 → ... (infinite)    │  │
              │  └──────────────────────────┘  │
              │                                │
              │  Pool Library Functions:       │
              │  • swap()                      │
              │  • modifyPosition()            │
              │  • initialize()                │
              └────────────────────────────────┘

   All pools in ONE contract
   Internal calls = CHEAP
```

---

## 💻 How It Works: Code Comparison

### V3 Style (Old Way)
```solidity
// V3: Factory creates NEW contracts
contract UniswapV3Factory {
    mapping(address => mapping(address => mapping(uint24 => address)))
        public pools;

    function createPool(address tokenA, address tokenB, uint24 fee) {
        // Deploy a WHOLE NEW CONTRACT for this pool
        address pool = new UniswapV3Pool{salt: ...}();
        pools[tokenA][tokenB][fee] = pool;
    }
}

