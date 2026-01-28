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
        afterRemoveLiquidityReturnDelta: false
    });
}
```

```
┌────────────────────────────────────────────────────────┐
│  Permission Checklist                                  │
│                                                        │
│  Think of this as a job application:                   │
│  "Which services can your hook provide?"               │
│                                                        │
│  □ beforeInitialize      - Setup new pools            │
│  □ afterInitialize       - React to new pools         │
│  □ beforeAddLiquidity    - Check liquidity additions  │
│  □ afterAddLiquidity     - React to liquidity adds    │
│  □ beforeRemoveLiquidity - Check liquidity removals   │
│  □ afterRemoveLiquidity  - React to liquidity removals│
│  ✓ beforeSwap            - Run before swaps           │
│  ✓ afterSwap             - Run after swaps            │
│  □ beforeDonate          - Check donations            │
│  □ afterDonate           - React to donations         │
│  □ Other advanced options...                          │
│                                                        │
│  We only checked 2 boxes: beforeSwap & afterSwap      │
│  → Our hook only cares about swaps!                   │
└────────────────────────────────────────────────────────┘
```

**Why does this matter?**

```
┌──────────────────────────────────────────────────────────┐
│  Permission → Address Bits                               │
│                                                          │
│  Your contract's address MUST have specific bits set     │
│  based on these permissions!                             │
│                                                          │
│  Example:                                                │
│  beforeSwap: true  → Bit 6 must be 1                     │
│  afterSwap: true   → Bit 7 must be 1                     │
│                                                          │
│  Valid address:   0x...0C0 (bits 6 & 7 = 1)             │
│  Invalid address: 0x...000 (bits 6 & 7 = 0)             │
│                                                          │
│  This is enforced by CREATE2 deployment with HookMiner   │
│                                                          │
│  Why? Security!                                          │
│  → Prevents hooks from being called for functions        │
│    they don't implement                                  │
│  → Address itself proves which functions are available   │
│  → Can't lie about capabilities                          │
└──────────────────────────────────────────────────────────┘
```

---

### The Hook Functions

#### beforeSwap

```solidity
function _beforeSwap(
    address,
    PoolKey calldata,
    SwapParams calldata,
    bytes calldata
) internal override returns (bytes4, BeforeSwapDelta, uint24) {
    // Logic before swap
    return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
}
```

```
┌──────────────────────────────────────────────────────────┐
│  Parameter Breakdown                                     │
│                                                          │
│  address              → Who is swapping?                 │
│  PoolKey calldata     → Which pool?                      │
│  SwapParams calldata  → Swap details (amount, direction) │
│  bytes calldata       → Custom data (hookData)           │
│                                                          │
│  Why unnamed (no variable names)?                        │
│  → We're not using them in this simple example          │
│  → Saves gas (doesn't copy to memory)                   │
│  → Still type-checked at compile time                    │
│                                                          │
│  "calldata" = Read-only parameter                        │
│  → Can't be modified                                     │
│  → Cheapest to use                                       │
│  → Like looking at a menu vs buying it                   │
└──────────────────────────────────────────────────────────┘
```

**Return Values:**

```
┌──────────────────────────────────────────────────────────┐
│  What We Return                                          │
│                                                          │
│  1. bytes4 selector                                      │
│     = BaseHook.beforeSwap.selector                       │
│     Purpose: "Yes, I successfully executed!"             │
│     Like: Signing a receipt                              │
│                                                          │
│  2. BeforeSwapDelta                                      │
│     = BeforeSwapDeltaLibrary.ZERO_DELTA                  │
│     Purpose: "I didn't modify the swap amounts"          │
│     Like: "No changes to the order"                      │
│                                                          │
│  3. uint24 (fee override)                                │
│     = 0                                                  │
│     Purpose: "Use the pool's default fee"                │
│     Like: "No special discount"                          │
└──────────────────────────────────────────────────────────┘
```

**When does this run?**

```
USER SWAPS:
┌─────────────────────────────────────────┐
│ 1. User calls router.swap()             │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 2. Router calls poolManager.swap()      │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 3. PoolManager checks: "Does this pool  │
│    have a hook with beforeSwap?"        │
│    → YES! Call it!                      │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 4. **YOUR CODE RUNS HERE** ←←←          │
│    _beforeSwap() executes               │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 5. PoolManager executes the actual swap │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ 6. PoolManager calls _afterSwap()       │
│    (if hook has afterSwap permission)   │
└─────────────────────────────────────────┘
```

#### afterSwap

```solidity
function _afterSwap(
    address,
    PoolKey calldata key,
    SwapParams calldata,
    BalanceDelta,
    bytes calldata
) internal override returns (bytes4, int128) {
    // Increment swap count for this pool
    swapCount[key.toId()]++;

    return (BaseHook.afterSwap.selector, 0);
}
```

**Line-by-Line:**

```
Line: swapCount[key.toId()]++;

Step 1: key.toId()
        → Convert PoolKey to PoolId (hash it)
        Example: PoolKey{TokenA, TokenB, fee, ...}
                 → 0xabcd1234...

Step 2: swapCount[0xabcd1234...]
        → Look up current count for this pool
        Example: Currently 5

Step 3: swapCount[0xabcd1234...]++
        → Increment by 1
        Example: 5 → 6

Visual:
┌─────────────────────────────────────┐
│  Before swap:                       │
│  swapCount[poolId] = 5              │
│  ┌─────┬─────┬─────┬─────┬─────┐   │
│  │  ■  │  ■  │  ■  │  ■  │  ■  │   │
│  └─────┴─────┴─────┴─────┴─────┘   │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  After swap:                        │
│  swapCount[poolId] = 6              │
│  ┌─────┬─────┬─────┬─────┬─────┬───┐│
│  │  ■  │  ■  │  ■  │  ■  │  ■  │ ■ ││
│  └─────┴─────┴─────┴─────┴─────┴───┘│
└─────────────────────────────────────┘
```

**Return Values:**

```
return (BaseHook.afterSwap.selector, 0);
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^  ^
        |                             |
        Confirmation signature        Fee adjustment (0 = none)
```

---

## PointsHook - Line by Line

Now let's look at the more advanced `PointsHook.sol`.

### Key Differences from MyFirstHook

```
┌────────────────────────────────────────────────────────┐
│  MyFirstHook vs PointsHook                             │
├────────────────────────────────────────────────────────┤
│                                                        │
│  MyFirstHook:                                          │
│  • Counts swaps per pool                               │
│  • Simple counter                                      │
│  • No user tracking                                    │
│  • Beginner-friendly                                   │
│                                                        │
│  PointsHook:                                           │
│  • Awards points to users                              │
│  • Tracks per user per pool                            │
│  • Multiple hook functions                             │
│  • Includes view functions for queries                 │
│  • Production-ready pattern                            │
└────────────────────────────────────────────────────────┘
```

### State Variables

```solidity
mapping(address => mapping(PoolId => uint256)) public userPoints;
```

```
┌──────────────────────────────────────────────────────────┐
│  Nested Mapping = Spreadsheet                            │
│                                                          │
│                Pool ABC    Pool DEF    Pool XYZ          │
│              ┌───────────┬───────────┬───────────┐       │
│  Alice       │    100    │     50    │     0     │       │
│  Bob         │     75    │    200    │    10     │       │
│  Charlie     │      0    │     30    │   150     │       │
│              └───────────┴───────────┴───────────┘       │
│                                                          │
│  How to read it:                                         │
│  userPoints[Alice][poolABC] = 100                        │
│  userPoints[Bob][poolDEF] = 200                          │
│  userPoints[Charlie][poolXYZ] = 150                      │
│                                                          │
│  Like a game where each player has separate scores       │
│  for each level:                                         │
│  Player 1: Level 1 (100 pts), Level 2 (50 pts)          │
│  Player 2: Level 1 (75 pts), Level 2 (200 pts)          │
└──────────────────────────────────────────────────────────┘
```

```solidity
mapping(PoolId => uint256) public totalSwaps;
mapping(PoolId => uint256) public totalLiquidityOps;
```

**Simple counters per pool:**

```
┌─────────────────────────────────────┐
│  Pool Statistics                    │
│                                     │
│  Pool ABC:                          │
│  • totalSwaps = 543                 │
│  • totalLiquidityOps = 42           │
│                                     │
│  Pool DEF:                          │
│  • totalSwaps = 1,234               │
│  • totalLiquidityOps = 67           │
│                                     │
│  Like a restaurant keeping track:   │
│  • Total orders served: 543         │
│  • Total supplier deliveries: 42    │
└─────────────────────────────────────┘
```

### Constants

```solidity
uint256 public constant POINTS_PER_SWAP = 10;
uint256 public constant POINTS_PER_LIQUIDITY = 50;
```

```
┌──────────────────────────────────────────────┐
│  constant = Fixed value, never changes       │
│                                              │
│  Benefits:                                   │
│  1. Gas efficient (compiler replaces it)     │
│  2. Clear naming (POINTS_PER_SWAP vs 10)     │
│  3. Easy to update (change in one place)     │
│  4. Can't be accidentally modified           │
│                                              │
│  Like:                                       │
│  const TAX_RATE = 0.08;                      │
│  vs                                          │
│  mysteriously using 0.08 everywhere          │
└──────────────────────────────────────────────┘
```

### The _afterSwap Function

```solidity
function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    PoolId poolId = key.toId();
    userPoints[sender][poolId] += POINTS_PER_SWAP;
    totalSwaps[poolId]++;
    return (BaseHook.afterSwap.selector, 0);
}
```

**Flow Diagram:**

```
┌────────────────────────────────────────────────────┐
│  Alice swaps in Pool ABC                           │
└──────────┬─────────────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────────┐
│  1. PoolId poolId = key.toId();                    │
│     → poolId = 0xABC123...                         │
└──────────┬─────────────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────────┐
│  2. userPoints[sender][poolId] += 10;              │
│     → userPoints[Alice][0xABC] += 10               │
│                                                    │
│     Before: Alice has 50 points in Pool ABC        │
│     After:  Alice has 60 points in Pool ABC        │
│                                                    │
│     ┌───────────────────────────┐                 │
│     │  Alice's Wallet           │                 │
│     │  Pool ABC Points: 50→60   │                 │
│     └───────────────────────────┘                 │
└──────────┬─────────────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────────┐
│  3. totalSwaps[poolId]++;                          │
│     → totalSwaps[0xABC]++                          │
│                                                    │
│     Before: 543 total swaps                        │
│     After:  544 total swaps                        │
│                                                    │
│     ┌───────────────────────────┐                 │
│     │  Pool ABC Statistics      │                 │
│     │  Total Swaps: 543→544     │                 │
│     └───────────────────────────┘                 │
└──────────┬─────────────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────────┐
│  4. return (BaseHook.afterSwap.selector, 0);       │
│     → "Successfully executed, no fee changes"      │
└────────────────────────────────────────────────────┘
```

### The _afterAddLiquidity Function

```solidity
function _afterAddLiquidity(
    address sender,
    PoolKey calldata key,
    ModifyLiquidityParams calldata params,
    BalanceDelta delta,
    BalanceDelta feesAccrued,
    bytes calldata hookData
) internal override returns (bytes4, BalanceDelta) {
    PoolId poolId = key.toId();
    userPoints[sender][poolId] += POINTS_PER_LIQUIDITY;
    totalLiquidityOps[poolId]++;
    return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
}
```

**What's Different?**

```
┌──────────────────────────────────────────────────────┐
│  _afterSwap vs _afterAddLiquidity                    │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Parameters:                                         │
│  afterSwap:                                          │
│  • SwapParams (amount, direction)                    │
│  • BalanceDelta (token changes)                      │
│                                                      │
│  afterAddLiquidity:                                  │
│  • ModifyLiquidityParams (tick range, amount)        │
│  • BalanceDelta (tokens deposited)                   │
│  • BalanceDelta feesAccrued (fees earned)            │
│                                                      │
│  Returns:                                            │
│  afterSwap:                                          │
│  • (bytes4, int128) - selector + fee adjustment      │
│                                                      │
│  afterAddLiquidity:                                  │
│  • (bytes4, BalanceDelta) - selector + delta         │
│                                                      │
│  Points Awarded:                                     │
│  • Swap: 10 points                                   │
│  • Add Liquidity: 50 points (5x more!)               │
│                                                      │
│  Why more for liquidity?                             │
│  → Liquidity providers help the pool function        │
│  → They take on risk (impermanent loss)              │
│  → Their capital is locked up                        │
│  → We want to incentivize them more!                 │
└──────────────────────────────────────────────────────┘
```

### View Functions

```solidity
function getPoints(address user, PoolId poolId) external view returns (uint256) {
    return userPoints[user][poolId];
}
```

```
┌──────────────────────────────────────────────────────┐
│  View Function = Read-Only Query                     │
│                                                      │
│  Properties:                                         │
│  • external: Can be called from outside the contract │
│  • view: Doesn't modify state (read-only)            │
│  • returns: Gives back a value                       │
│                                                      │
│  Like querying a database:                           │
│  SELECT points FROM userPoints                       │
│  WHERE user = 'Alice' AND poolId = '0xABC';          │
│                                                      │
│  Usage from frontend:                                │
│  const points = await pointsHook.getPoints(          │
│    aliceAddress,                                     │
│    poolId                                            │
│  );                                                  │
│  console.log(`Alice has ${points} points`);          │
└──────────────────────────────────────────────────────┘
```

---

## Key Differences

### Comparison Table

```
┌───────────────────────────────────────────────────────────────┐
│  Feature              MyFirstHook         PointsHook          │
├───────────────────────────────────────────────────────────────┤
│  Complexity           Simple              Advanced            │
│  State Variables      1 mapping           3 mappings          │
│  Hook Functions       2 (before/afterSwap)3 (swap + liquidity)│
│  View Functions       0                   3                   │
│  User Tracking        No                  Yes                 │
│  Constants            No                  Yes                 │
│  Documentation        Basic               Extensive           │
│  Production Ready     No                  Getting there       │
└───────────────────────────────────────────────────────────────┘
```

### Evolution Path

```
┌─────────────────────────────────────────────────────────┐
│  Learning Progression                                   │
│                                                         │
│  Step 1: MyFirstHook                                    │
│  • Learn basic hook structure                           │
│  • Understand permissions                               │
│  • See simple state tracking                            │
│  • Master return values                                 │
│                                                         │
│  Step 2: PointsHook                                     │
│  • Per-user tracking                                    │
│  • Multiple hook types                                  │
│  • View functions for queries                           │
│  • Constants and organization                           │
│                                                         │
│  Step 3: Your Custom Hook                               │
│  • Combine patterns                                     │
│  • Add business logic                                   │
│  • Implement access control                             │
│  • Deploy to production                                 │
└─────────────────────────────────────────────────────────┘
```

### When to Use Each Pattern

```
┌──────────────────────────────────────────────────────────┐
│  Use MyFirstHook-style when:                             │
│  ✓ Learning hooks                                        │
│  ✓ Building a prototype                                  │
│  ✓ Only need pool-level stats                            │
│  ✓ Don't care about individual users                     │
│                                                          │
│  Examples:                                               │
│  • Volume tracker (just count swaps)                     │
│  • Pool activity monitor                                 │
│  • Simple on-chain analytics                             │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  Use PointsHook-style when:                              │
│  ✓ Need user-specific data                               │
│  ✓ Building an incentive system                          │
│  ✓ Want queryable data                                   │
│  ✓ Planning for frontend integration                     │
│                                                          │
│  Examples:                                               │
│  • Loyalty programs                                      │
│  • Trading competitions                                  │
│  • Liquidity mining                                      │
│  • User dashboards                                       │
└──────────────────────────────────────────────────────────┘
```

---

## Summary

```
┌────────────────────────────────────────────────────────────┐
│  🎓 What You've Learned                                    │
│                                                            │
│  ✓ How hooks plug into Uniswap v4                          │
│  ✓ What each line of code does                             │
│  ✓ Why permissions matter                                  │
│  ✓ How state variables store data                          │
│  ✓ When hook functions execute                             │
│  ✓ How to track users vs pools                             │
│  ✓ The difference between simple and advanced patterns     │
│                                                            │
│  🚀 Next Steps                                             │
│                                                            │
│  1. Run the tests: forge test -vv                          │
│  2. Modify point values                                    │
│  3. Add your own state variables                           │
│  4. Create a custom hook                                   │
│  5. Deploy to testnet                                      │
│                                                            │
│  Remember: Every expert was once a beginner!               │
│  Break things, fix them, learn from mistakes.              │
└────────────────────────────────────────────────────────────┘
```

---

*Take your time with this material. Refer back to these diagrams as you experiment with the code. Understanding takes practice!*
