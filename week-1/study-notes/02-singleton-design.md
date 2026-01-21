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

// Result: Pool lives at 0xABC123... (separate contract address)
```

### V4 Style (New Way)
```solidity
// V4: Library with reusable logic
library Pool {
    function swap(State storage self, ...) {
        // Swap logic here
    }

    function modifyPosition(State storage self, ...) {
        // Liquidity logic here
    }
}

// V4: PoolManager uses the library
contract PoolManager {
    using Pool for *;

    // All pools stored in ONE mapping
    mapping(PoolId => Pool.State) internal pools;

    function swap(PoolId id, ...) {
        // Call library function on the pool's state
        pools[id].swap(...);  // Internal call, NOT external!
    }
}

// Result: Pool is just data in the PoolManager contract
```

---

## 🔑 Key Differences

| Aspect | V3 (Multi-Contract) | V4 (Singleton) |
|--------|---------------------|----------------|
| **Pool Storage** | Separate contract per pool | All pools in PoolManager |
| **Code Execution** | Each pool has its own code | Shared library functions |
| **Function Calls** | External (expensive) | Internal (cheap) |
| **Pool Creation** | Deploy new contract | Add entry to mapping |
| **Multi-hop Swaps** | Call multiple contracts | Call one contract multiple times |
| **Gas Cost** | Higher | Lower |

---

## 📦 What is Pool.State?

Think of `Pool.State` as a folder that contains all the information about a pool:

```
Pool.State Folder:
├── 📊 Current Price (sqrtPriceX96)
├── 📍 Current Tick
├── 💰 Liquidity Amount
├── 🎯 Fee Configuration
├── 🔗 Hook Address (if any)
├── 📈 Observation Data (for price history)
└── 🔐 Lock Status
```

In V3, each pool contract had these as storage variables.
In V4, they're all packed into a struct stored in the PoolManager.

---

## 🎨 Visual: How Pool Data is Accessed

### V3 - External Contract Calls
```
User → SwapRouter → Pool Contract (0xABC...)
                     ↓
                  pool.slot0()  ← External call
                  pool.swap()   ← External call

External calls = More gas
```

### V4 - Internal Library Calls
```
User → SwapRouter → PoolManager
                     ↓
                  pools[id].swap()  ← Library call (internal)
                  ↓
                  Pool Library applies logic to Pool.State

Internal calls = Less gas
```

---

## 🚀 Benefits of Singleton Design

### 1. **Cheaper Pool Creation**
```
V3: Deploy new contract     = ~5,000,000 gas
V4: Add mapping entry       = ~100,000 gas

Savings: 98% cheaper! 🎉
```

### 2. **Cheaper Multi-Hop Swaps**
```
Swap: ETH → USDC → DAI

V3 Flow:
  User → ETH/USDC Pool (transfer ETH, get USDC)
       → Transfer USDC to next pool
       → USDC/DAI Pool (transfer USDC, get DAI)
       → Transfer DAI to user

  = 4 external token transfers

V4 Flow:
  User → PoolManager (send ETH)
       → Internal: Calculate USDC amount
       → Internal: Calculate DAI amount
       → PoolManager (receive DAI)

  = 2 external token transfers

Savings: 50% fewer transfers! 🎉
```

### 3. **Unified Liquidity Management**
All pools managed by one contract = easier to build tools, better composability

---

## 🧩 How Libraries Make This Possible

**Library**: A piece of reusable code that doesn't store its own data, but operates on data you give it.

```
Analogy: Recipe Book vs Kitchen

❌ V3 Approach: Each pool is a full kitchen
   • Kitchen A: Has recipe book + ingredients + tools
   • Kitchen B: Has recipe book + ingredients + tools
   • Kitchen C: Has recipe book + ingredients + tools

✅ V4 Approach: PoolManager is ONE kitchen with a recipe book
   • Recipe book (Pool library): Shared cooking instructions
   • Ingredients (Pool.State): Different for each pool
   • Kitchen (PoolManager): Executes recipes on different ingredients
```

---

## 🔗 Resources & Citations

1. **Atrium Academy - V4 Architecture**
   https://learn.atrium.academy/course/4b6c25df-f4c8-4b92-ab38-a930284d237e/technical-introduction/v4-architecture

2. **Uniswap V4 PoolManager Code**
   https://github.com/Uniswap/v4-core/blob/main/src/PoolManager.sol

3. **Solidity Libraries Documentation**
   https://docs.soliditylang.org/en/latest/contracts.html#libraries

---

## ✅ Quick Self-Check

1. **What does "singleton" mean in V4?**
   <details>
   <summary>Answer</summary>
   One single PoolManager contract manages all pools, instead of each pool being its own contract.
   </details>

2. **How does V4 store pool data?**
   <details>
   <summary>Answer</summary>
   As Pool.State structs in a mapping inside the PoolManager contract.
   </details>

3. **Why are library calls cheaper than external contract calls?**
   <details>
   <summary>Answer</summary>
   Library calls are internal to the contract (like calling your own function), while external calls require leaving the contract and entering another one, which costs more gas.
   </details>

4. **What's the main benefit of singleton design for multi-hop swaps?**
   <details>
   <summary>Answer</summary>
   You don't need to transfer tokens between different contracts at each step - everything happens inside the PoolManager.
   </details>

---

**Previous**: [Uniswap V4 Overview](./01-uniswap-v4-overview.md)
**Next**: [Flash Accounting](./03-flash-accounting.md)
