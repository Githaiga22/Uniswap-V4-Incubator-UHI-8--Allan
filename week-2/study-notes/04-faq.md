# Uniswap v4 Hooks - Frequently Asked Questions

This document answers common questions about building Uniswap v4 hooks, with visual aids and real-world analogies.

---

## Table of Contents
1. [How do hook addresses and function selectors work together?](#question-1)
2. [How do you know what hook to use for a particular use case?](#question-2)
3. [Can we add our own custom functions in the hook?](#question-3)
4. [Do we need to specify remappings in foundry.toml?](#question-4)
5. [Will the code be shared/published later?](#question-5)
6. [Is msg.sender reliable with account abstraction?](#question-6)
7. [What exactly is hookData and how do we use it?](#question-7)
8. [What happens if amountSpecified is 0?](#question-8)
9. [How does zeroForOne affect which tokens are swapped?](#question-9)
10. [Why is delta.amount0() negative in some swaps?](#question-10)

---

## Question 1: Hook Addresses and Function Selectors
### "When the address of the hook is taken into account, is this override return byte4 related to the address bits that work with afterSwap?"

**Short Answer:** No, they're separate but related concepts. The address bits determine WHICH functions your hook can implement. The bytes4 selector you return confirms the function executed SUCCESSFULLY.

Let's break this down with an analogy:

### 🏠 The Restaurant Analogy

```
┌─────────────────────────────────────────┐
│         RESTAURANT ADDRESS              │
│  123 Main Street (Binary: 0x...1010)    │
│                                         │
│  The address ENCODES what services      │
│  the restaurant offers:                 │
│  - Bit 1: Breakfast ✓                   │
│  - Bit 2: Lunch ✗                       │
│  - Bit 3: Dinner ✓                      │
│  - Bit 4: Catering ✓                    │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│      FUNCTION SELECTOR (bytes4)         │
│                                         │
│  When a customer orders breakfast,      │
│  the chef returns a receipt saying:     │
│  "✓ Breakfast served successfully!"     │
│                                         │
│  This is like returning:                │
│  BaseHook.afterSwap.selector            │
└─────────────────────────────────────────┘
```

### How it Actually Works

```
HOOK ADDRESS (last 14 bits encode permissions):
┌───────────────────────────────────────────────────┐
│  0x...0000000000000000000000000000000000000A10    │
│                                         ▲    ▲    │
│                                         │    │    │
│                      These 14 bits ─────┴────┘    │
│                      encode which hooks            │
│                      are implemented               │
└───────────────────────────────────────────────────┘

Example bit meanings (simplified):
Bit 0: beforeInitialize
Bit 1: afterInitialize
Bit 2: beforeAddLiquidity
Bit 3: afterAddLiquidity
Bit 4: beforeRemoveLiquidity
Bit 5: afterRemoveLiquidity
Bit 6: beforeSwap
Bit 7: afterSwap ← If this bit is SET, afterSwap can be called
... and so on

FUNCTION SELECTOR (bytes4):
┌─────────────────────────────────────────┐
│  bytes4(keccak256("afterSwap(...)"))    │
│  = 0x3dce6c64                           │
│                                         │
│  This is returned to prove:             │
│  "Yes, I successfully executed!"        │
└─────────────────────────────────────────┘
```

### Step-by-Step Example

```solidity
// STEP 1: Your hook declares it implements afterSwap
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        // ... other permissions false ...
        afterSwap: true,  // ← This flag MUST match the address bit!
        // ...
    });
}

// STEP 2: Deploy to an address where bit 7 is SET
// The HookMiner finds: 0x...0080 (where bit 7 = 1)

// STEP 3: Implement the function
function _afterSwap(...) internal override returns (bytes4, int128) {
    // Your logic here
    userPoints[sender][poolId] += 10;

    // STEP 4: Return the selector to confirm success
    return (BaseHook.afterSwap.selector, 0);
    //      ^^^^^^^^^^^^^^^^^^^^^^^^^^^
    //      This is the bytes4 that confirms
    //      "afterSwap executed successfully!"
}
```

### Visual Flow Diagram

```
┌──────────────┐
│  Pool Swap   │
│   Happens    │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│  PoolManager checks hook address             │
│  "Does bit 7 (afterSwap) = 1?"               │
│  Address: 0x...0080                          │
│  Bit 7: YES ✓                                │
└──────┬───────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│  PoolManager calls hook.afterSwap()          │
│  Hook executes logic                         │
│  Hook returns: (0x3dce6c64, 0)              │
└──────┬───────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│  PoolManager verifies return value           │
│  Expected: 0x3dce6c64                        │
│  Received: 0x3dce6c64                        │
│  Match! ✓ Continue execution                 │
└──────────────────────────────────────────────┘
```

**Key Takeaway:**
- **Address bits** = Permission to implement the function (enforced at deployment)
- **bytes4 selector** = Proof that function executed correctly (checked at runtime)

---

## Question 2: Choosing the Right Hook
### "How do you know what hook to use for a particular use case?"

Think of hooks like event listeners in web development. Choose based on WHEN you need your code to run.

### 🎯 Decision Tree

```
                    ┌─────────────────────┐
                    │  What do you want   │
                    │    to track/do?     │
                    └──────────┬──────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
           ▼                   ▼                   ▼
    ┌──────────┐        ┌──────────┐       ┌──────────┐
    │  Swaps   │        │Liquidity │       │  Other   │
    └─────┬────┘        └─────┬────┘       └─────┬────┘
          │                   │                   │
     ┌────┴────┐         ┌────┴────┐         ┌────┴────┐
     ▼         ▼         ▼         ▼         ▼         ▼
  Before    After    Before    After    Before    After
   Swap      Swap     Add       Add      Init      Donate
                    Liquidity Liquidity
```

### Common Use Cases by Hook Type

#### afterSwap
**When:** After every swap completes
**Use Cases:**
- ✅ Award loyalty points (like our PointsHook)
- ✅ Track trading volume
- ✅ Collect custom fees
- ✅ Update price oracles
- ✅ Trigger external actions (emit events)

```
Real-world analogy: Like a cash register that prints
a receipt AFTER you pay. The transaction is done,
now we record it.
```

#### beforeSwap
**When:** Before a swap executes (can modify or reject)
**Use Cases:**
- ✅ Implement access control (whitelist/blacklist)
- ✅ Apply custom fees
- ✅ Enforce trading limits
- ✅ Implement circuit breakers
- ✅ Check KYC requirements

```
Real-world analogy: Like a bouncer at a club who
checks your ID BEFORE letting you in. Can reject entry.
```

#### afterAddLiquidity
**When:** After someone adds liquidity
**Use Cases:**
- ✅ Reward liquidity providers
- ✅ Mint LP tokens or NFTs
- ✅ Track liquidity depth
- ✅ Trigger rebalancing

```
Real-world analogy: Like getting a receipt after
depositing money in a bank.
```

#### beforeAddLiquidity
**When:** Before someone adds liquidity
**Use Cases:**
- ✅ Restrict who can provide liquidity
- ✅ Enforce minimum amounts
- ✅ Apply deposit fees
- ✅ Check pool capacity limits

```
Real-world analogy: Like a bank checking if you're
eligible to open an account before you deposit.
```

### 📋 Quick Reference Table

| Want to...                          | Use This Hook              |
|-------------------------------------|---------------------------|
| Track swap volume                   | `afterSwap`               |
| Block certain addresses from swapping | `beforeSwap`            |
| Reward LPs with points              | `afterAddLiquidity`       |
| Enforce max pool size               | `beforeAddLiquidity`      |
| Create custom pool types            | `beforeInitialize`        |
| Take fees on swaps                  | `beforeSwap` or `afterSwap` |
| Update external contracts           | `after*` hooks            |
| Modify amounts                      | `before*` hooks with return delta |

### Example: Building a Trading Competition Hook

```
Goal: Award points for swaps, extra points for large swaps

Choose: afterSwap (need to see final swap amounts)

function _afterSwap(..., BalanceDelta delta, ...) internal override {
    uint256 points = 10; // Base points

    // Check swap size
    if (abs(delta.amount0()) > 1 ether) {
        points += 20; // Bonus for large swaps
    }

    userPoints[sender][poolId] += points;
    return (BaseHook.afterSwap.selector, 0);
}
```

**Pro Tip:** You can implement MULTIPLE hooks in one contract!

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeSwap: true,   // Check whitelist
        afterSwap: true,    // Award points
        afterAddLiquidity: true, // Bonus points for LPs
        // ... others false
    });
}
```

---

## Question 3: Custom Functions
### "Can we add our own functions in the hook? Are we limited by what's encoded in the address?"

**Great question!** Let's clarify:

### 🎭 Two Types of Functions

```
┌─────────────────────────────────────────────────────────┐
│                   YOUR HOOK CONTRACT                    │
│                                                         │
│  ┌───────────────────────────────────────────────┐    │
│  │  HOOK CALLBACKS (Limited by address bits)    │    │
│  │  These are called BY the PoolManager          │    │
│  │                                               │    │
│  │  • beforeSwap()                               │    │
│  │  • afterSwap()         ← Only 10 possible     │    │
│  │  • afterAddLiquidity()   functions            │    │
│  │  • etc...                                     │    │
│  └───────────────────────────────────────────────┘    │
│                                                         │
│  ┌───────────────────────────────────────────────┐    │
│  │  YOUR CUSTOM FUNCTIONS (Unlimited!)           │    │
│  │  These are called BY users directly           │    │
│  │                                               │    │
│  │  • getPoints(user, pool)                      │    │
│  │  • claimRewards()                             │    │
│  │  • updateSettings()        ← Add as many      │    │
│  │  • withdrawFees()            as you want!     │    │
│  │  • whatever()                                 │    │
│  └───────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### The Limit Explained

```
ADDRESS ENCODING (14 bits = 14 possible hook callbacks):
┌────────────────────────────────────────┐
│  14 bits = 14 hook callback functions  │
│                                        │
│  Bit 0:  beforeInitialize              │
│  Bit 1:  afterInitialize               │
│  Bit 2:  beforeAddLiquidity            │
│  Bit 3:  afterAddLiquidity             │
│  Bit 4:  beforeRemoveLiquidity         │
│  Bit 5:  afterRemoveLiquidity          │
│  Bit 6:  beforeSwap                    │
│  Bit 7:  afterSwap                     │
│  Bit 8:  beforeDonate                  │
│  Bit 9:  afterDonate                   │
│  Bit 10: beforeSwapReturnDelta         │
│  Bit 11: afterSwapReturnDelta          │
│  Bit 12: afterAddLiqReturnDelta        │
│  Bit 13: afterRemoveLiqReturnDelta     │
│                                        │
│  These 14 are ALL the hooks that       │
│  PoolManager can call automatically    │
└────────────────────────────────────────┘

YOUR CUSTOM FUNCTIONS (No limit!):
┌────────────────────────────────────────┐
│  Not encoded in address!               │
│  Add as many as you want:              │
│                                        │
│  • Public view functions               │
│  • State-changing functions            │
│  • Admin functions                     │
│  • Helper functions                    │
│  • Integration functions               │
│  • Literally anything else!            │
└────────────────────────────────────────┘
```

### Real Example from PointsHook

```solidity
contract PointsHook is BaseHook {

    // ═══════════════════════════════════════════════════
    // HOOK CALLBACKS (Limited to 14, encoded in address)
    // ═══════════════════════════════════════════════════

    function _afterSwap(...) internal override returns (bytes4, int128) {
        // Called by PoolManager automatically
        userPoints[sender][poolId] += POINTS_PER_SWAP;
        return (BaseHook.afterSwap.selector, 0);
    }

    function _afterAddLiquidity(...) internal override returns (bytes4, BalanceDelta) {
        // Called by PoolManager automatically
        userPoints[sender][poolId] += POINTS_PER_LIQUIDITY;
        return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    // ═══════════════════════════════════════════════════
    // CUSTOM FUNCTIONS (Unlimited! Not in address!)
    // ═══════════════════════════════════════════════════

    // View function - anyone can call
    function getPoints(address user, PoolId poolId) external view returns (uint256) {
        return userPoints[user][poolId];
    }

    // Custom state-changing function - you could add this!
    function claimRewards(PoolId poolId) external {
        uint256 points = userPoints[msg.sender][poolId];
        require(points >= 100, "Need 100 points to claim");

        userPoints[msg.sender][poolId] = 0;
        // Transfer rewards...
    }

    // Admin function - you could add this!
    function updatePointRates(uint256 newSwapPoints) external onlyOwner {
        POINTS_PER_SWAP = newSwapPoints;
    }

    // Helper function - you could add this!
    function getTopUsers(PoolId poolId, uint256 limit) external view returns (address[] memory) {
        // Return leaderboard...
    }

    // Integration function - you could add this!
    function migratePointsToToken(PoolId poolId) external {
        uint256 points = userPoints[msg.sender][poolId];
        // Mint ERC20 tokens based on points...
    }
}
```

### 🍕 Pizza Shop Analogy

```
Hook Address = The sign on your pizza shop
┌─────────────────────────────────────────┐
│     MARIO'S PIZZA                       │
│                                         │
│  [✓] Takes Orders  ← These are encoded │
│  [✓] Bakes Pizza      in your address  │
│  [✓] Delivers         (hook callbacks) │
│  [✗] Catering                           │
└─────────────────────────────────────────┘

But inside, you can offer UNLIMITED extras:
┌─────────────────────────────────────────┐
│  INSIDE THE SHOP:                       │
│                                         │
│  • Loyalty card program                 │
│  • Check points balance                 │
│  • Redeem free pizza                    │
│  • View order history                   │
│  • Rate your order                      │
│  • Refer a friend                       │
│  • Join pizza club                      │
│  • Buy merchandise                      │
│  ... whatever you want!                 │
└─────────────────────────────────────────┘
```

### Code Example: Adding Custom Functions

```solidity
contract AdvancedPointsHook is BaseHook {
    // Hook callbacks (limited to 14)
    function _afterSwap(...) internal override returns (bytes4, int128) {
        // Required hook logic
    }

    // ===== YOUR CUSTOM EMPIRE STARTS HERE =====

    // Leaderboard function
