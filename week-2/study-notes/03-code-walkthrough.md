# Complete Code Walkthrough: Understanding Your Hooks Line-by-Line

This document explains **MyFirstHook.sol** and **PointsHook.sol** with detailed analogies and visual aids.

---

## Table of Contents
1. [Understanding the Basics](#understanding-the-basics)
2. [MyFirstHook - Line by Line](#myfirsthook-line-by-line)
3. [PointsHook - Line by Line](#pointshook-line-by-line)
4. [Key Differences](#key-differences)

---

## Understanding the Basics

Before we dive into the code, let's understand what a hook is:

```
┌────────────────────────────────────────────────────────────┐
│                    THE UNISWAP v4 POOL                      │
│                                                            │
│     Token A ←→ Pool ←→ Token B                             │
│                  ↑                                         │
│                  │                                         │
│        ┌─────────┴──────────┐                             │
│        │     YOUR HOOK      │                             │
│        │   "Plugin Code"    │                             │
│        │                    │                             │
│        │  • beforeSwap()    │                             │
│        │  • afterSwap()     │                             │
│        │  • beforeAddLiq()  │                             │
│        │  • afterAddLiq()   │                             │
│        └────────────────────┘                             │
│                                                            │
│  Hooks are like plugins that run when things happen       │
│  in the pool (swaps, adding liquidity, etc.)              │
└────────────────────────────────────────────────────────────┘
```

### The Restaurant Analogy

Think of Uniswap v4 as a restaurant:

```
┌─────────────────────────────────────────────────────┐
│               THE RESTAURANT (Uniswap v4)            │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Kitchen (PoolManager)                              │
│  ├── Takes orders (swap requests)                   │
│  ├── Prepares food (executes swaps)                 │
│  └── Manages inventory (pool liquidity)             │
│                                                     │
│  YOUR HOOK = A Special Service                      │
│  ├── beforeSwap = "Before taking order"             │
│  │   → Check customer ID, apply discounts           │
│  │                                                   │
│  ├── afterSwap = "After serving food"               │
│  │   → Award loyalty points, clean table            │
│  │                                                   │
│  ├── beforeAddLiquidity = "Before accepting supply" │
│  │   → Verify supplier credentials                  │
│  │                                                   │
│  └── afterAddLiquidity = "After stocking inventory" │
│      → Record supplier contribution, give receipt   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## MyFirstHook - Line by Line

Let's dissect `MyFirstHook.sol` piece by piece.

### The Opening: License and Version

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
```

**What this means:**
- `SPDX-License-Identifier`: Like a copyright notice. "MIT" = "Anyone can use this code freely"
- `pragma solidity ^0.8.24`: "This code needs Solidity version 0.8.24 or higher"

**Analogy:** Like requiring "Microsoft Word 2020 or later" to open a document.

---

### The Imports: Getting Our Tools

```solidity
import {BaseHook} from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
```

```
Think of imports like tool rental:

┌─────────────────────────────────────┐
│     TOOL RENTAL SHOP                │
├─────────────────────────────────────┤
│                                     │
│  You rent:                          │
│  📦 BaseHook                        │
│     → Basic hook foundation         │
│     → Handles communication with    │
│       PoolManager                   │
│     → Enforces correct pattern      │
│                                     │
└─────────────────────────────────────┘

Without BaseHook, you'd have to build everything from scratch!
It's like building a house with pre-made walls vs cutting trees.
```

```solidity
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
```

**What it is:** A library with permission flags and validation logic.

```
┌──────────────────────────────────────┐
│  Hooks Library = Permission Checker  │
│                                      │
│  Contains:                           │
│  • BEFORE_SWAP_FLAG = 0x0040        │
│  • AFTER_SWAP_FLAG = 0x0080         │
│  • validateHookPermissions()        │
│  • ... more flags and helpers       │
└──────────────────────────────────────┘
```

```solidity
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
```

**What it is:** The interface to talk to the PoolManager (the main Uniswap v4 contract).

```
┌────────────────────────────────────────┐
│  IPoolManager = Phone Directory        │
│                                        │
│  Lists all functions you can call:     │
│  • swap()                              │
│  • modifyLiquidity()                   │
│  • initialize()                        │
│  • ...etc                              │
│                                        │
│  Like knowing the restaurant's menu    │
│  before you visit                      │
└────────────────────────────────────────┘
```

```solidity
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
```

**What they are:** Types to identify pools.

```
┌────────────────────────────────────────────┐
│  PoolKey vs PoolId                         │
├────────────────────────────────────────────┤
│                                            │
│  PoolKey = Full Address                    │
│  ┌──────────────────────────────────┐     │
│  │ Currency0: Token A               │     │
│  │ Currency1: Token B               │     │
│  │ Fee: 3000 (0.3%)                 │     │
│  │ TickSpacing: 60                  │     │
│  │ Hooks: 0x123...                  │     │
│  └──────────────────────────────────┘     │
│          │                                 │
│          │ Hash it!                        │
│          ▼                                 │
│  PoolId = Short Hash                       │
│  0xabcd...1234                             │
│  (Like a tracking number)                  │
│                                            │
│  Analogy:                                  │
│  PoolKey = Full mailing address            │
│  PoolId = Zip code + house number          │
│           (shorter, faster lookups)        │
└────────────────────────────────────────────┘
```

```solidity
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
```

**What it is:** Tracks how token balances changed.

```
┌─────────────────────────────────────────┐
│  BalanceDelta = Change in Balance       │
│                                         │
│  Before swap:                           │
│  Pool has: 100 TokenA, 100 TokenB       │
│                                         │
│  User swaps: 10 TokenA → ??? TokenB     │
│                                         │
│  After swap:                            │
│  Pool has: 110 TokenA, 90 TokenB        │
│                                         │
│  BalanceDelta:                          │
│  • amount0 = +10 (received TokenA)      │
│  • amount1 = -10 (sent TokenB)          │
│                                         │
│  Like a bank statement showing:         │
│  Deposit: +$10                          │
│  Withdrawal: -$10                       │
└─────────────────────────────────────────┘
```

```solidity
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
```

**What they are:** Types for swap operations.

---

### The Contract Declaration

```solidity
contract MyFirstHook is BaseHook {
```

```
┌──────────────────────────────────────────────┐
│  Inheritance Diagram                         │
│                                              │
│     BaseHook (Parent class)                  │
│         ↑                                    │
│         │ inherits from                      │
│         │                                    │
│    MyFirstHook (Child class)                 │
│                                              │
│  MyFirstHook gets all the powers of BaseHook │
│  + adds its own custom logic                 │
│                                              │
│  Like: Tesla Model 3 IS A Car               │
│        └─ Has all car features               │
│        └─ Plus electric motor, autopilot     │
└──────────────────────────────────────────────┘
```

---

### Using the Library

```solidity
using PoolIdLibrary for PoolKey;
```

**What this does:** Adds helper functions to PoolKey type.

```
┌──────────────────────────────────────────────┐
│  "using" = Adding Methods                    │
│                                              │
│  Before:                                     │
│  PoolId id = PoolIdLibrary.toId(key);        │
│              ^^^^^^^^^^^^^^^^                │
│              (Long, verbose)                 │
│                                              │
│  After:                                      │
│  PoolId id = key.toId();                     │
│              ^^^^^^^^                        │
│              (Short, clean!)                 │
│                                              │
│  Analogy:                                    │
│  Before: "Please convert this address        │
│           to a zip code using the            │
│           ZipCodeLibrary"                    │
│  After:  "Address, give me your zip code"   │
│          (Direct, like a method call)        │
└──────────────────────────────────────────────┘
```

---

### State Variables

```solidity
// State variables
mapping(PoolId => uint256) public swapCount;
```

```
┌──────────────────────────────────────────────────┐
│  Mapping = Dictionary / Phonebook                │
│                                                  │
│  Structure:                                      │
│  ┌───────────┬──────────┐                       │
│  │ PoolId    │ Count    │                       │
│  ├───────────┼──────────┤                       │
│  │ 0xABC...  │    5     │ ← Pool ABC had 5 swaps│
│  │ 0xDEF...  │   12     │ ← Pool DEF had 12     │
│  │ 0x123...  │    0     │ ← Pool 123 had none   │
│  └───────────┴──────────┘                       │
│                                                  │
│  Usage:                                          │
│  swapCount[poolId] = 10;    // Set              │
│  uint256 count = swapCount[poolId]; // Get      │
│  swapCount[poolId]++;       // Increment        │
│                                                  │
│  Analogy:                                        │
│  Like counting how many times each restaurant    │
│  served customers:                               │
│  Restaurant A: 50 customers today                │
│  Restaurant B: 33 customers today                │
└──────────────────────────────────────────────────┘
```

**Why `public`?**
```
public = Automatically creates a getter function

// You can call from outside:
uint256 count = myHook.swapCount(poolId);

// Compiler creates this for you:
function swapCount(PoolId poolId) public view returns (uint256) {
    return _swapCount[poolId];
}
```

---

### Constructor

```solidity
constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}
```

```
┌──────────────────────────────────────────────────────┐
│  Constructor = Birth Certificate                     │
│                                                      │
│  What happens when contract is deployed:             │
│                                                      │
│  Step 1: Deploy with address of PoolManager          │
│          new MyFirstHook(0xPoolManager...)           │
│                          ^^^^^^^^^^^                 │
│                          This address                │
│                                                      │
│  Step 2: Pass it to parent (BaseHook)                │
│          BaseHook(_poolManager)                      │
│          ^^^^^^^^^^^^^^^^^^^^^^                      │
│          Parent stores this address                  │
│                                                      │
│  Step 3: BaseHook validates the address              │
│          "Does this hook address have the            │
│           correct permission bits?"                  │
│                                                      │
│  Like:                                               │
│  1. Baby is born (contract deployed)                 │
│  2. Parents register the birth (pass to BaseHook)    │
│  3. Hospital checks paperwork (validates permissions)│
└──────────────────────────────────────────────────────┘
```

---

### Hook Permissions

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeInitialize: false,
        afterInitialize: false,
        beforeAddLiquidity: false,
        afterAddLiquidity: false,
        beforeRemoveLiquidity: false,
        afterRemoveLiquidity: false,
        beforeSwap: true,    // ← We implement this!
        afterSwap: true,     // ← We implement this!
        beforeDonate: false,
        afterDonate: false,
        beforeSwapReturnDelta: false,
        afterSwapReturnDelta: false,
        afterAddLiquidityReturnDelta: false,
