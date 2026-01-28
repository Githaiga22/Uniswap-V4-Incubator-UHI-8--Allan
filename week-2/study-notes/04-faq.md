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
    function getTopTraders(PoolId poolId) external view returns (address[10] memory) {
        // Return top 10 traders by points
    }

    // Referral system
    function setReferrer(address referrer) external {
        referrers[msg.sender] = referrer;
    }

    // Points marketplace
    function transferPoints(address to, PoolId poolId, uint256 amount) external {
        userPoints[msg.sender][poolId] -= amount;
        userPoints[to][poolId] += amount;
    }

    // Burn points for NFT
    function mintBadge(PoolId poolId) external returns (uint256 tokenId) {
        require(userPoints[msg.sender][poolId] >= 1000, "Need 1000 points");
        userPoints[msg.sender][poolId] -= 1000;
        // Mint NFT...
    }

    // Integration with external protocol
    function stakingRewardMultiplier(address user, PoolId poolId) external view returns (uint256) {
        // Other protocols can call this to boost staking rewards
        // based on trading points
        return userPoints[user][poolId] / 100;
    }

    // Admin dashboard
    function getPoolStats(PoolId poolId) external view returns (
        uint256 totalSwaps,
        uint256 totalUsers,
        uint256 totalPointsIssued
    ) {
        // Return analytics...
    }
}
```

**Summary:**
- ❌ **Limited:** Hook callback functions (14 max, encoded in address)
- ✅ **Unlimited:** Your own custom functions (as many as you want!)

---

## Question 4: Remappings in Foundry
### "Do we need to specify remappings in foundry.toml or does it read from a file?"

**Short Answer:** You should specify them in `foundry.toml` for best results. Let me explain the options.

### 📁 Where Foundry Looks for Remappings

```
┌─────────────────────────────────────────────────────────────┐
│  REMAPPING PRIORITY (Foundry checks in this order):        │
│                                                             │
│  1. foundry.toml ← RECOMMENDED (Most explicit)              │
│  2. remappings.txt (Legacy, still works)                    │
│  3. Auto-generated from lib/ structure (Implicit)           │
│  4. Command line: forge build --remappings                  │
└─────────────────────────────────────────────────────────────┘
```

### What Are Remappings?

Remappings tell the compiler how to resolve imports. Think of them as shortcuts or aliases.

```
WITHOUT REMAPPING:
import "../../lib/v4-core/src/interfaces/IPoolManager.sol";
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
       Long, brittle, breaks if you move files!

WITH REMAPPING:
import "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
       ^^^^^^^^^^^^^^^^
       Short, clear, portable!
```

### Visual Example

```
YOUR PROJECT STRUCTURE:
┌─────────────────────────────────────┐
│  myproject/                         │
│  ├── foundry.toml                   │
│  ├── src/                           │
│  │   └── PointsHook.sol             │
│  └── lib/                           │
│      ├── v4-core/                   │
│      │   └── src/                   │
│      │       └── interfaces/        │
│      │           └── IPoolManager..│
│      └── v4-periphery/              │
│          └── src/                   │
│              └── utils/             │
│                  └── BaseHook.sol   │
└─────────────────────────────────────┘

IN YOUR CODE:
import "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
       ^^^^^^^^^^^^^^^^
       This needs to resolve to:
       lib/v4-core/src/interfaces/IPoolManager.sol

REMAPPING SAYS:
"@uniswap/v4-core/" = "lib/v4-core/"
```

### Option 1: foundry.toml (RECOMMENDED)

```toml
# foundry.toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.26"

# Remappings - explicit and clear!
remappings = [
    "@uniswap/v4-core/=lib/v4-core/",
    "@uniswap/v4-periphery/=lib/v4-periphery/",
    "forge-std/=lib/forge-std/src/",
    "@openzeppelin/contracts/=lib/v4-core/lib/openzeppelin-contracts/contracts/",
    "solmate/=lib/v4-core/lib/solmate/"
]
```

**Pros:**
- ✅ Everything in one config file
- ✅ Easy to read and maintain
- ✅ Version controlled with your project
- ✅ IDE support is better
- ✅ Clear and explicit

**Cons:**
- None really!

### Option 2: remappings.txt (Legacy)

```
# remappings.txt (in project root)
@uniswap/v4-core/=lib/v4-core/
@uniswap/v4-periphery/=lib/v4-periphery/
forge-std/=lib/forge-std/src/
```

**Pros:**
- ✅ Simpler syntax
- ✅ Works with older Foundry versions

**Cons:**
- ❌ Extra file to maintain
- ❌ Less flexible
- ❌ Can be overridden by foundry.toml (confusing)

### Option 3: Auto-generated

Foundry can auto-generate remappings based on your `lib/` structure:

```bash
forge remappings > remappings.txt
```

**Pros:**
- ✅ Automatic

**Cons:**
- ❌ May not create the names you want
- ❌ May not handle nested dependencies well
- ❌ Needs to be regenerated if lib/ changes

### 🎯 Best Practice

Use `foundry.toml` with explicit remappings:

```toml
[profile.default]
remappings = [
    # Main dependencies
    "@uniswap/v4-core/=lib/v4-core/",
    "@uniswap/v4-periphery/=lib/v4-periphery/",

    # Testing framework
    "forge-std/=lib/forge-std/src/",

    # Sub-dependencies (nested in v4-core)
    "@openzeppelin/contracts/=lib/v4-core/lib/openzeppelin-contracts/contracts/",
    "solmate/=lib/v4-core/lib/solmate/"
]
```

### Troubleshooting Remappings

```
ERROR: "FileNotFound: @uniswap/v4-core/src/interfaces/IPoolManager.sol"

Diagnosis steps:
1. Check if remapping is in foundry.toml ✓
2. Check if path exists:
   ls lib/v4-core/src/interfaces/IPoolManager.sol ✓
3. Check remapping syntax:
   "@uniswap/v4-core/"  ← Must end with /
   "lib/v4-core/"       ← Must end with /
4. Run: forge remappings (see what Foundry thinks)
5. Try: forge clean && forge build
```

### Common Remapping Patterns

```toml
# Pattern 1: Direct mapping (simple)
"forge-std/=lib/forge-std/src/"

# Pattern 2: Nested dependencies (complex)
"@openzeppelin/contracts/=lib/v4-core/lib/openzeppelin-contracts/contracts/"
                          ^^^^^^^^^^^^^^^^^
                          Goes through v4-core first!

# Pattern 3: Multiple versions (rare)
"@uniswap/v4-core-v1/=lib/v4-core-v1/"
"@uniswap/v4-core-v2/=lib/v4-core-v2/"
```

### Testing Your Remappings

```bash
# View current remappings
forge remappings

# Expected output:
# @uniswap/v4-core/=lib/v4-core/
# @uniswap/v4-periphery/=lib/v4-periphery/
# ...

# Try to build
forge build

# If it works, your remappings are correct! ✓
```

**Summary:**
- 📌 **Use foundry.toml** for remappings (recommended)
- 📄 remappings.txt works but is legacy
- 🤖 Auto-generation can help but verify the output
- 🔍 Always test with `forge build`

---

## 🎓 Additional Resources

### Quick Command Reference

```bash
# Build your project
forge build

# Run tests
forge test

# Run specific test
forge test --match-test testSwapAwardsPoints

# Verbose output (see what's happening)
forge test -vvvv

# Gas report
forge test --gas-report

# Check remappings
forge remappings

# Clean build artifacts
forge clean

# Format code
forge fmt
```

### Learning Path

```
1. ✓ Set up environment (you're here!)
2. → Read and understand PointsHook.sol
3. → Run the tests: forge test -vv
4. → Modify the points values and re-test
5. → Add a new custom function
6. → Create your own hook from scratch
7. → Deploy to a testnet
```

### Common Pitfalls

```
❌ Wrong: Using public/external for hook callbacks
✅ Right: Use internal with underscore prefix (_afterSwap)

❌ Wrong: Forgetting to return the correct selector
✅ Right: Always return (BaseHook.functionName.selector, ...)

❌ Wrong: Not mining correct address salt
✅ Right: Use HookMiner to find correct salt

❌ Wrong: Implementing hooks not in getHookPermissions()
✅ Right: Only implement hooks where permission = true
```

---

## Question 5: Code Sharing and Publishing
### "Will the code be shared/published later?"

**Short Answer:** Yes! This code is meant to be shared, learned from, and built upon. Here's what you should know about sharing hook code.

### 📢 Why Share Your Hooks?

Sharing your hook code benefits the entire DeFi ecosystem:

```
┌──────────────────────────────────────────────────────────┐
│              BENEFITS OF OPEN SOURCE HOOKS               │
│                                                          │
│  For You:                                                │
│  ✓ Get feedback and code reviews                        │
│  ✓ Build reputation in the community                    │
│  ✓ Others may improve your code                         │
│  ✓ Easier to audit and trust                            │
│                                                          │
│  For Community:                                          │
│  ✓ Learn from real examples                             │
│  ✓ Reuse patterns and utilities                         │
│  ✓ Discover new use cases                               │
│  ✓ Accelerate innovation                                │
└──────────────────────────────────────────────────────────┘
```

### 🎯 What to Share

```
RECOMMENDED TO SHARE:
├── ✅ Hook source code (MIT or similar license)
├── ✅ Test files
├── ✅ Documentation and comments
├── ✅ Deployment scripts
├── ✅ Architecture explanations
└── ✅ Known limitations

OPTIONAL TO SHARE:
├── 🟡 Deployment addresses
├── 🟡 Configuration parameters
└── 🟡 Integration guides

CONSIDER KEEPING PRIVATE (temporarily):
├── 🔒 Novel algorithms (until patent/publication)
├── 🔒 Production deployment keys
└── 🔒 Business-sensitive parameters
```

### How to Share

**Option 1: GitHub Repository (Recommended)**
```bash
# Initialize git if you haven't already
git init
git add .
git commit -m "Initial hook implementation"

# Create a repo on GitHub, then:
git remote add origin https://github.com/yourusername/your-hook
git push -u origin main
```

**Option 2: Package and Publish**
```bash
# If your hook is reusable, publish as a library
# Others can install via:
forge install yourusername/your-hook
```

**Option 3: Write a Blog Post**
- Explain your hook's purpose
- Walk through key design decisions
- Share deployment addresses on testnets
- Provide usage examples

### 📜 License Considerations

```solidity
// SPDX-License-Identifier: MIT  ← Choose appropriate license
pragma solidity ^0.8.24;

// Common licenses for DeFi:
// - MIT: Very permissive, most popular
// - GPL-3.0: Open source, derivatives must be open
// - Apache-2.0: Permissive with patent grant
// - BUSL-1.1: Business Source License (delayed open source)
```

### 🔐 Security Considerations Before Publishing

```
CHECKLIST BEFORE MAINNET DEPLOYMENT:
┌─────────────────────────────────────────┐
│ □ Code has been audited                 │
│ □ Tests achieve >90% coverage           │
│ □ Gas optimizations applied             │
│ □ Access controls properly implemented  │
│ □ Admin keys are multisig/timelock      │
│ □ Emergency pause mechanism exists      │
│ □ Upgrade path considered               │
│ □ Documentation is complete             │
└─────────────────────────────────────────┘
```

### Example: Publishing Your PointsHook

```markdown
# PointsHook - Loyalty Points for Uniswap v4

## Overview
Awards points to users for swapping and providing liquidity.

## Features
- 10 points per swap
- 50 points per liquidity addition
- Per-pool point tracking
- Query functions for points and stats

## Usage
```solidity
// Check your points
uint256 myPoints = pointsHook.getPoints(myAddress, poolId);

// Points are awarded automatically when you:
// 1. Swap in a pool using this hook
// 2. Add liquidity to a pool using this hook
```

## Deployment
See GETTING_STARTED.md for deployment instructions.

## License
MIT
```

### Community Standards

Following best practices helps others use your hooks:

```
GOOD README INCLUDES:
┌─────────────────────────────────────────┐
│ 1. Clear description of what it does    │
│ 2. Installation/setup instructions      │
│ 3. Usage examples                       │
│ 4. Architecture diagrams                │
│ 5. Known limitations                    │
│ 6. Contact info / how to contribute     │
│ 7. License information                  │
│ 8. Deployment addresses (if applicable) │
└─────────────────────────────────────────┘
```

**Remember:** Open source doesn't mean giving up control. You decide:
- What license to use
- When to publish
- What information to include
- How to handle contributions

---

## Question 6: Account Abstraction and msg.sender
### "A different user could sponsor someone else's transaction through account abstraction. This means msg.sender isn't reliable, right?"

**Excellent question!** You're absolutely correct to think about this. Let's break down the nuance.

### 🎭 The Account Abstraction Problem

```
TRADITIONAL TRANSACTION:
┌─────────────────────────────────────────────────┐
│  Alice (EOA)                                    │
│  0xAlice...                                     │
└──────────┬──────────────────────────────────────┘
           │ signs & pays gas
           ▼
┌─────────────────────────────────────────────────┐
│  PoolManager.swap()                             │
│  msg.sender = 0xAlice                           │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  Hook._afterSwap()                              │
│  sender parameter = 0xAlice ✓                   │
│  Award points to 0xAlice ✓                      │
└─────────────────────────────────────────────────┘
```

```
WITH ACCOUNT ABSTRACTION:
┌─────────────────────────────────────────────────┐
│  Bob (EOA) - Paying gas                         │
│  0xBob...                                       │
└──────────┬──────────────────────────────────────┘
           │ sponsors transaction
           ▼
┌─────────────────────────────────────────────────┐
│  Alice's Smart Wallet                           │
│  0xAliceWallet...                               │
└──────────┬──────────────────────────────────────┘
           │ executes on behalf of Alice
           ▼
┌─────────────────────────────────────────────────┐
│  PoolManager.swap()                             │
│  msg.sender = 0xAliceWallet (not 0xAlice!)      │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  Hook._afterSwap()                              │
│  sender parameter = 0xAliceWallet               │
│  Award points to 0xAliceWallet ✓                │
│  (This is actually correct!)                    │
└─────────────────────────────────────────────────┘
```

### 🎯 The Truth About sender in Uniswap v4 Hooks

**Key Insight:** The `sender` parameter in hook callbacks is NOT `msg.sender`!

```solidity
function _afterSwap(
    address sender,  // ← This is the ORIGINAL caller, not msg.sender!
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    // sender = the address that initiated the swap with PoolManager
    // This is already the smart wallet address in AA scenarios
    userPoints[sender][poolId] += POINTS_PER_SWAP;
}
```

### 📊 Visual Comparison

```
WHAT YOU MIGHT THINK HAPPENS:
msg.sender = Bob (sponsor)      ← ❌ Wrong!
Award points to Bob             ← ❌ Wrong!

WHAT ACTUALLY HAPPENS:
sender param = Alice's Wallet   ← ✅ Correct!
Award points to Alice's Wallet  ← ✅ Correct!
```

### Why This Works

Uniswap v4's PoolManager tracks who called it:

```solidity
// Simplified PoolManager logic
function swap(PoolKey memory key, SwapParams memory params) external {
    address caller = msg.sender; // Could be EOA or smart wallet

    // ... perform swap ...

    // Pass the CALLER to the hook, not msg.sender inside the hook
    IHooks(key.hooks).afterSwap(
        caller,  // ← The actual swapper
        key,
        params,
        delta,
        hookData
    );
}
```

### 🤔 When Should You Care About This?

**Scenario 1: Tracking "Users"**

If you want to track actual users (not just wallet addresses):

```solidity
// This works! Smart wallets are the "user" in v4
function _afterSwap(
    address sender,  // This is the smart wallet address
    ...
) internal override returns (bytes4, int128) {
    userPoints[sender][poolId] += POINTS_PER_SWAP;
    // If Alice uses wallet 0xABC, points go to 0xABC ✓
    // If Alice later uses wallet 0xDEF, that's a different "user"
    return (BaseHook.afterSwap.selector, 0);
}
```

**Scenario 2: Real Identity Tracking (Advanced)**

If you need to link smart wallets to real identities:

```solidity
// Option A: Use a registry
mapping(address => address) public smartWalletToOwner;

function registerWallet(address owner) external {
    smartWalletToOwner[msg.sender] = owner;
}

function _afterSwap(address sender, ...) internal override returns (bytes4, int128) {
    address realOwner = smartWalletToOwner[sender];
    if (realOwner != address(0)) {
        userPoints[realOwner][poolId] += POINTS_PER_SWAP;
    } else {
        userPoints[sender][poolId] += POINTS_PER_SWAP;
    }
    return (BaseHook.afterSwap.selector, 0);
}
```

**Scenario 3: Integrating with ERC-6551 (Token Bound Accounts)**

```solidity
// If using token-bound accounts:
interface IERC6551Registry {
    function account(address implementation, uint256 chainId, address tokenContract, uint256 tokenId, uint256 salt) external view returns (address);
}

function getTokenOwner(address accountAddress) internal view returns (address) {
    // Query the NFT that owns this account...
}
```

### 🎮 Real-World Example: Gaming Hook

```solidity
/**
 * Scenario: Game rewards players for trading in-game assets
 * Players use smart wallets (AA) for better UX
 */
contract GamingHook is BaseHook {
    // Map smart wallets to player IDs
    mapping(address => uint256) public walletToPlayerId;

    function registerPlayer(uint256 playerId) external {
        walletToPlayerId[msg.sender] = playerId;
    }

    function _afterSwap(address sender, ...) internal override returns (bytes4, int128) {
        uint256 playerId = walletToPlayerId[sender];

        if (playerId != 0) {
            // Award to specific player
            playerPoints[playerId] += POINTS_PER_SWAP;
        } else {
            // Award to wallet address (unregistered user)
            walletPoints[sender] += POINTS_PER_SWAP;
        }

        return (BaseHook.afterSwap.selector, 0);
    }
}
```

### Summary

```
┌────────────────────────────────────────────────────────┐
│  KEY POINTS:                                           │
│                                                        │
│  ✓ The 'sender' parameter is reliable                 │
│  ✓ It represents the address that called PoolManager  │
│  ✓ In AA scenarios, it's the smart wallet address     │
│  ✓ This is usually what you want!                     │
│                                                        │
│  Only worry about "real" identity if you need to:     │
│  • Link multiple wallets to one user                  │
│  • Integrate with existing identity systems           │
│  • Implement cross-wallet features                    │
│                                                        │
│  Default behavior (tracking by sender) works for:     │
│  • Point systems ✓                                    │
│  • Access control ✓                                   │
│  • Fee tracking ✓                                     │
│  • Volume statistics ✓                                │
└────────────────────────────────────────────────────────┘
```

---

## Question 7: Understanding hookData
### "I don't really understand hookData. What does it contain exactly? Can you give specific examples?"

**Great question!** `hookData` is one of the most flexible and powerful features of Uniswap v4 hooks.

### 🎁 What is hookData?

```
hookData = Custom data passed from the caller to your hook

┌──────────────────────────────────────────┐
│  User calls:                             │
│  router.swap(key, params, "some data")   │
│                            ^^^^^^^^^^^    │
│                            This becomes   │
│                            hookData!      │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  PoolManager forwards it:                │
│  hook.afterSwap(..., "some data")        │
│                       ^^^^^^^^^^^         │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  Your hook receives it:                  │
│  function _afterSwap(                    │
│      address sender,                     │
│      PoolKey calldata key,               │
│      SwapParams calldata params,         │
│      BalanceDelta delta,                 │
│      bytes calldata hookData  ← HERE!    │
│  )                                       │
└──────────────────────────────────────────┘
```

### 📦 Think of hookData as a Package

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│         📦  PACKAGE (hookData)                       │
│                                                      │
│  "Dear Hook,                                         │
│   Here's some extra info about this transaction:    │
│   - Referrer address: 0xBob                          │
│   - Promo code: "SUMMER2024"                         │
│   - User preference: dark mode                       │
│   - Whatever else we want to tell you!"              │
│                                                      │
│  Sender can pack ANYTHING in here!                   │
│  Hook can read and act on it!                        │
└──────────────────────────────────────────────────────┘
```

### 🔧 Example 1: Referral System

**Use Case:** Track who referred each user, award bonus points.

```solidity
// In your hook:
function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    PoolId poolId = key.toId();

    // Decode the hookData to get referrer address
    address referrer = address(0);

    if (hookData.length >= 20) {
        // First 20 bytes = address of referrer
        referrer = address(bytes20(hookData[0:20]));
    }

    // Award points to swapper
    userPoints[sender][poolId] += POINTS_PER_SWAP;

    // Award bonus points to referrer
    if (referrer != address(0) && referrer != sender) {
        userPoints[referrer][poolId] += REFERRAL_BONUS; // 5 extra points!
    }

    return (BaseHook.afterSwap.selector, 0);
}

// How a user calls it:
// router.swap(key, swapParams, abi.encodePacked(referrerAddress));
//                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//                              This becomes hookData!
```

**User Flow:**
```solidity
// Alice was referred by Bob
address bob = 0xBob...;

// When Alice swaps, she passes Bob's address in hookData:
bytes memory hookData = abi.encodePacked(bob);
router.swap(poolKey, swapParams, hookData);

// Result:
// Alice gets 10 points
// Bob gets 5 points (referral bonus!)
```

### 🔧 Example 2: Discount Codes

**Use Case:** Apply discount if user provides valid promo code.

```solidity
contract DiscountHook is BaseHook {
    mapping(bytes32 => uint256) public promoCodeDiscounts; // code => discount %

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        // Set up promo codes
        promoCodeDiscounts[keccak256("SUMMER2024")] = 50; // 50% off
        promoCodeDiscounts[keccak256("NEWUSER")] = 80;    // 80% off
    }

    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        uint24 feeOverride = key.fee; // Default fee

        // Check if promo code provided
        if (hookData.length > 0) {
            bytes32 codeHash = keccak256(hookData);
            uint256 discount = promoCodeDiscounts[codeHash];

            if (discount > 0) {
                // Apply discount to fee
                feeOverride = uint24(key.fee * (100 - discount) / 100);
            }
        }

        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            feeOverride // Return discounted fee!
        );
    }
}

// How to use:
// bytes memory promoCode = bytes("SUMMER2024");
// router.swap(key, params, promoCode);
```

### 🔧 Example 3: Complex Data Structure

**Use Case:** Pass multiple pieces of information.

```solidity
// Define a struct for your data
struct TradeMetadata {
    address referrer;
    uint8 loyaltyTier;    // 0 = bronze, 1 = silver, 2 = gold
    bool isFirstTrade;
    uint32 campaignId;
}

function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    PoolId poolId = key.toId();

    // Base points
    uint256 points = POINTS_PER_SWAP;

    // Decode complex data if provided
    if (hookData.length > 0) {
        TradeMetadata memory metadata = abi.decode(hookData, (TradeMetadata));

        // Loyalty tier multiplier
        if (metadata.loyaltyTier == 1) points = points * 15 / 10; // 1.5x silver
        if (metadata.loyaltyTier == 2) points = points * 2;       // 2x gold

        // First trade bonus
        if (metadata.isFirstTrade) points += 100;

        // Referrer bonus
        if (metadata.referrer != address(0)) {
            userPoints[metadata.referrer][poolId] += REFERRAL_BONUS;
        }

        // Campaign tracking
        campaignVolume[metadata.campaignId] += uint256(abs(delta.amount0()));
    }

    userPoints[sender][poolId] += points;

    return (BaseHook.afterSwap.selector, 0);
}

// How to use:
TradeMetadata memory metadata = TradeMetadata({
    referrer: 0xBob...,
    loyaltyTier: 2,        // Gold tier
    isFirstTrade: true,
    campaignId: 12345
});

bytes memory hookData = abi.encode(metadata);
router.swap(key, params, hookData);
```

### 🔧 Example 4: Conditional Execution

**Use Case:** Hook behavior changes based on a flag.

```solidity
function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    // Check first byte for mode
    uint8 mode = 0;
    if (hookData.length > 0) {
        mode = uint8(hookData[0]);
    }

    if (mode == 0) {
        // Mode 0: Regular points
        userPoints[sender][key.toId()] += POINTS_PER_SWAP;
    } else if (mode == 1) {
        // Mode 1: Charity mode - donate points to charity pool
        charityPoints[key.toId()] += POINTS_PER_SWAP;
    } else if (mode == 2) {
        // Mode 2: Fast mode - no points, just execute quickly
        // Skip point tracking to save gas
    }

    return (BaseHook.afterSwap.selector, 0);
}

// Usage:
// Normal swap: router.swap(key, params, abi.encodePacked(uint8(0)));
// Charity:     router.swap(key, params, abi.encodePacked(uint8(1)));
// Fast:        router.swap(key, params, abi.encodePacked(uint8(2)));
```

### 🔧 Example 5: Signature Verification

**Use Case:** Verify off-chain authorization.

```solidity
function _beforeSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    bytes calldata hookData
) internal override returns (bytes4, BeforeSwapDelta, uint24) {
    // Require signature from authorized oracle
    if (hookData.length == 65) { // Standard signature length
        bytes32 messageHash = keccak256(abi.encodePacked(
            sender,
            key.toId(),
            params.amountSpecified,
            block.timestamp / 1 hours // Valid for 1 hour
        ));

        bytes32 ethSignedHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));

        address signer = recoverSigner(ethSignedHash, hookData);

        require(signer == authorizedOracle, "Invalid signature");
    }

    return (
        BaseHook.beforeSwap.selector,
        BeforeSwapDeltaLibrary.ZERO_DELTA,
        0
    );
}
```

### 📋 Summary: When to Use hookData

```
USE HOOKDATA FOR:
┌──────────────────────────────────────────────────────────┐
│ ✓ Referral tracking                                      │
│ ✓ Promo codes / discounts                                │
│ ✓ User preferences                                       │
│ ✓ Additional context about the transaction              │
│ ✓ Authorization signatures                               │
│ ✓ Campaign tracking                                      │
│ ✓ Conditional logic (modes/flags)                        │
│ ✓ Off-chain computed data                                │
│ ✓ Integration with external systems                      │
└──────────────────────────────────────────────────────────┘

DON'T USE HOOKDATA FOR:
┌──────────────────────────────────────────────────────────┐
│ ✗ Data already in PoolKey or SwapParams                  │
│ ✗ Data that should be stored on-chain (use state vars)  │
│ ✗ Secret information (it's public on chain!)            │
│ ✗ Critical security checks (validate, don't just trust) │
└──────────────────────────────────────────────────────────┘
```

### 🎯 Best Practices

```solidity
// 1. Always check length before decoding
if (hookData.length > 0) {
    // Safe to decode
}

// 2. Use try-catch for complex decoding
try this.decodeHookData(hookData) returns (CustomData memory data) {
    // Use data
} catch {
    // Handle invalid data gracefully
}

// 3. Document expected format
/**
 * @notice Expected hookData format:
 * - Bytes 0-19: Referrer address (address, 20 bytes)
 * - Byte 20: Loyalty tier (uint8, 1 byte)
 * - Bytes 21-52: Signature (bytes32, 32 bytes)
 */

// 4. Provide default behavior for empty hookData
if (hookData.length == 0) {
    // Default: no referrer, no bonus
    userPoints[sender][poolId] += POINTS_PER_SWAP;
    return (...);
}
```

### Real-World Integration

```solidity
// Frontend code (JavaScript/TypeScript)
import { ethers } from 'ethers';

// Encode referrer address
const referrerAddress = "0x1234...";
const hookData = ethers.solidityPacked(['address'], [referrerAddress]);

// Or encode complex struct
const hookData = ethers.AbiCoder.defaultAbiCoder().encode(
    ['tuple(address,uint8,bool,uint32)'],
    [[referrerAddress, 2, true, 12345]]
);

// Use in swap
await router.swap(poolKey, swapParams, hookData);
```

**Key Takeaway:** `hookData` is an open-ended communication channel between transaction initiators and your hook. Use it creatively!

---

## Question 8: Zero Amount Swaps
### "What if amountSpecified is 0? Would the swap go through?"

**Short Answer:** No! A swap with amountSpecified = 0 will fail. You're absolutely correct in your thinking - it's like asking for 1000 USDC in exchange for 0 ETH, which makes no sense economically.

### 🎯 Why Zero Swaps Don't Work

```
┌────────────────────────────────────────────────────────┐
│  The Zero Swap Problem                                 │
│                                                        │
│  User says: "I want to swap 0 tokens"                  │
│                                                        │
│  Questions that arise:                                 │
│  • How much do you get back? (Can't calculate!)        │
│  • What's the price impact? (Division by zero!)        │
│  • Should fees be charged? (0% of 0 = meaningless)     │
│  • Did anything actually happen? (No!)                 │
│                                                        │
│  It's economically undefined!                          │
└────────────────────────────────────────────────────────┘
```

### 💰 The Trading Analogy

```
AT A CURRENCY EXCHANGE:

You: "I want to exchange money"
Clerk: "How much?"
You: "Zero dollars"
Clerk: "... then why are you here?"

┌────────────────────────────────────────────────┐
│  Exchange Booth                                │
│                                                │
│  You have:    $0                               │
│  You want:    ¥??? (Can't determine!)          │
│  Exchange rate: $1 = ¥100                      │
│  Result:      $0 × 100 = ¥0                    │
│                                                │
│  You walk away with nothing.                   │
│  The clerk is confused.                        │
│  No transaction occurred.                      │
└────────────────────────────────────────────────┘
```

### 🔢 Technical Explanation

```solidity
struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;  // ← This is the amount
    uint160 sqrtPriceLimitX96;
}

// When amountSpecified = 0:
SwapParams memory params = SwapParams({
    zeroForOne: true,
    amountSpecified: 0,  // ❌ Problem!
    sqrtPriceLimitX96: PRICE_LIMIT
});
```

**What happens internally:**

```
┌──────────────────────────────────────────────────────┐
│  PoolManager.swap() validation                       │
│                                                      │
│  Step 1: Check amountSpecified                       │
│  if (amountSpecified == 0) {                         │
│      revert SwapAmountCannotBeZero();                │
│  }                                                   │
│                                                      │
│  Step 2: Calculate swap...                           │
│  // Never reached if amount is 0                     │
└──────────────────────────────────────────────────────┘
```

### 📊 Visual: Valid vs Invalid Swaps

```
VALID SWAP (Positive Amount):
┌─────────────────────────────────────────┐
│  User: "I want to swap 1 ETH"           │
│  Pool: "You'll receive 1800 USDC"       │
│  ✓ Clear input                          │
│  ✓ Calculable output                    │
│  ✓ Transaction executes                 │
└─────────────────────────────────────────┘

Pool Before:  [1000 ETH] ←→ [1,800,000 USDC]
              ↓ User swaps 1 ETH
Pool After:   [1001 ETH] ←→ [1,798,200 USDC]
              User receives 1800 USDC

INVALID SWAP (Zero Amount):
┌─────────────────────────────────────────┐
│  User: "I want to swap 0 ETH"           │
│  Pool: "Error! Cannot be zero!"         │
│  ✗ Meaningless input                    │
│  ✗ Cannot calculate output              │
│  ✗ Transaction reverts                  │
└─────────────────────────────────────────┘

Pool Before:  [1000 ETH] ←→ [1,800,000 USDC]
              ↓ User tries to swap 0 ETH
              ❌ REVERTED
Pool After:   [1000 ETH] ←→ [1,800,000 USDC]
              (No change - transaction failed)
```

### 🧮 The Math Problem

```
AMM Pricing Formula (simplified):
output = (input × reserveOut) / (reserveIn + input)

With zero input:
output = (0 × reserveOut) / (reserveIn + 0)
output = 0 / reserveIn
output = 0

Problems:
1. Output is always 0 (not useful!)
2. Price impact = 0 (but nothing happened!)
3. Fees = 0 × fee_rate = 0 (no revenue for LPs)
4. Pool state unchanged (wasted gas)

It's technically computable but economically meaningless!
```

### 🎮 Real-World Code Example

```solidity
// This will REVERT:
function attemptZeroSwap() external {
    IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
        zeroForOne: true,
        amountSpecified: 0,  // ❌ Will fail!
        sqrtPriceLimitX96: MIN_PRICE_LIMIT
    });

    // This line will revert with SwapAmountCannotBeZero()
    poolManager.swap(poolKey, params, hookData);
}

// This will SUCCEED:
function attemptValidSwap() external {
    IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
        zeroForOne: true,
        amountSpecified: -1e18,  // ✓ Swapping 1 token (exact input)
        sqrtPriceLimitX96: MIN_PRICE_LIMIT
    });

    // This works!
    poolManager.swap(poolKey, params, hookData);
}
```

### ⚠️ Common Misconceptions

```
❌ WRONG: "Zero swap is a way to check the pool state"
✅ RIGHT: Use view functions instead:
          - pool.getSlot0() to get current price
          - pool.getLiquidity() to get liquidity

❌ WRONG: "Zero swap can be used to test if pool exists"
✅ RIGHT: Check if pool is initialized:
          - poolManager.isPoolInitialized(poolKey)

❌ WRONG: "Zero swap is gas-efficient for testing hooks"
✅ RIGHT: If you want to test hooks without actual swap:
          - Use a tiny amount (1 wei)
          - Or mock the PoolManager in tests
```

### 🔍 Edge Cases

**Minimum Swap Amounts:**

```
VERY SMALL SWAP (Still valid):
┌────────────────────────────────────────┐
│  amountSpecified = 1 wei               │
│  • Technically valid ✓                 │
│  • Might receive 0 tokens (rounding)   │
│  • Still pays gas                      │
│  • May fail due to slippage limits     │
└────────────────────────────────────────┘

Example:
Swap 1 wei of ETH
→ Receive 0.0000018 USDC
→ Rounds to 0 USDC
→ Swap succeeds but you get nothing!

This is why frontends usually enforce minimum swap amounts:
if (userInput < 0.001) {
    alert("Minimum swap: 0.001 ETH");
}
```

### Summary Diagram

```
┌─────────────────────────────────────────────────────┐
│  Swap Amount Decision Tree                          │
│                                                     │
│  amountSpecified = ???                              │
│         │                                           │
│         ├─ = 0 ────────────→ ❌ REVERT             │
│         │                     "SwapAmountCannotBeZero"│
│         │                                           │
│         ├─ > 0 (small) ────→ ⚠️  CAUTION           │
│         │                     Might receive 0       │
│         │                     due to rounding       │
│         │                                           │
│         └─ > 0 (reasonable)→ ✅ SUCCESS             │
│                              Normal swap            │
└─────────────────────────────────────────────────────┘
```

**Key Takeaways:**
- ❌ Zero swaps are rejected by the protocol
- 💭 It's like exchanging nothing for nothing
- ⚡ Use view functions to query pool state instead
- 🔬 For testing, use tiny but non-zero amounts

---

## Question 9: Token Direction
### "Currencies for amount0 and amount1 will swap if zeroForOne is set to false, right?"

**Excellent question!** You're absolutely right. The `zeroForOne` flag determines which direction the swap goes. Let's break this down visually.

### 🔄 Understanding zeroForOne

```
┌──────────────────────────────────────────────────────────┐
│  Pool Structure (Always Ordered)                         │
│                                                          │
│  ┌──────────────┐          ┌──────────────┐             │
│  │  Currency 0  │ ←──────→ │  Currency 1  │             │
│  │   (Token0)   │          │   (Token1)   │             │
│  └──────────────┘          └──────────────┘             │
│                                                          │
│  Note: Token0 address < Token1 address (sorted!)         │
│  Example: 0x0000...AAA < 0x0000...FFF                    │
└──────────────────────────────────────────────────────────┘
```

### 📊 The Two Swap Directions

```
DIRECTION 1: zeroForOne = true
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  ┌──────────────┐          ┌──────────────┐             │
│  │   Token 0    │  ──────→ │   Token 1    │             │
│  │   (Input)    │          │   (Output)   │             │
│  └──────────────┘          └──────────────┘             │
│                                                          │
│  User gives: Token0                                      │
│  User gets:  Token1                                      │
│                                                          │
│  Example: Swap ETH → USDC                                │
│  (if ETH is Token0, USDC is Token1)                      │
└──────────────────────────────────────────────────────────┘

DIRECTION 2: zeroForOne = false
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  ┌──────────────┐          ┌──────────────┐             │
│  │   Token 0    │  ←────── │   Token 1    │             │
│  │   (Output)   │          │   (Input)    │             │
│  └──────────────┘          └──────────────┘             │
│                                                          │
│  User gives: Token1                                      │
│  User gets:  Token0                                      │
│                                                          │
│  Example: Swap USDC → ETH                                │
│  (if ETH is Token0, USDC is Token1)                      │
└──────────────────────────────────────────────────────────┘
```

### 🎯 Concrete Example: ETH/USDC Pool

```
Pool Setup:
┌─────────────────────────────────────┐
│  Token0: ETH  (0x00...ABC)          │
│  Token1: USDC (0x00...XYZ)          │
│  (ABC < XYZ in address order)       │
└─────────────────────────────────────┘

Scenario A: Alice wants to buy USDC with ETH
┌──────────────────────────────────────────────────────────┐
│  Alice's Trade:                                          │
│  • Give: 1 ETH                                           │
│  • Get: ~1800 USDC                                       │
│                                                          │
│  Code:                                                   │
│  SwapParams({                                            │
│      zeroForOne: true,      ← ETH (0) → USDC (1)         │
│      amountSpecified: -1e18, ← Exact input: 1 ETH        │
│      ...                                                 │
│  })                                                      │
│                                                          │
│  Flow:                                                   │
│  ETH (Token0) ──→ Pool ──→ USDC (Token1)                 │
└──────────────────────────────────────────────────────────┘

Scenario B: Bob wants to buy ETH with USDC
┌──────────────────────────────────────────────────────────┐
│  Bob's Trade:                                            │
│  • Give: 1800 USDC                                       │
│  • Get: ~1 ETH                                           │
│                                                          │
│  Code:                                                   │
│  SwapParams({                                            │
│      zeroForOne: false,     ← USDC (1) → ETH (0)         │
│      amountSpecified: -1800e6, ← Exact input: 1800 USDC  │
│      ...                                                 │
│  })                                                      │
│                                                          │
│  Flow:                                                   │
│  USDC (Token1) ──→ Pool ──→ ETH (Token0)                 │
└──────────────────────────────────────────────────────────┘
```

### 🔢 How amount0 and amount1 Change

```
Initial Pool State:
┌──────────────────────────────────┐
│  Reserve0 (ETH):  1000           │
│  Reserve1 (USDC): 1,800,000      │
│  Price: 1 ETH = 1800 USDC        │
└──────────────────────────────────┘

SWAP WITH zeroForOne = true:
┌──────────────────────────────────────────────────────────┐
│  Alice swaps 1 ETH → ? USDC                              │
│                                                          │
│  Before:                                                 │
│  Reserve0: 1000 ETH                                      │
│  Reserve1: 1,800,000 USDC                                │
│                                                          │
│  Change (BalanceDelta):                                  │
│  amount0: +1 ETH      (Pool gained ETH)                  │
│  amount1: -1800 USDC  (Pool gave USDC)                   │
│                                                          │
│  After:                                                  │
│  Reserve0: 1001 ETH   (increased)                        │
│  Reserve1: 1,798,200 USDC (decreased)                    │
└──────────────────────────────────────────────────────────┘

SWAP WITH zeroForOne = false:
┌──────────────────────────────────────────────────────────┐
│  Bob swaps 1800 USDC → ? ETH                             │
│                                                          │
│  Before:                                                 │
│  Reserve0: 1001 ETH                                      │
│  Reserve1: 1,798,200 USDC                                │
│                                                          │
│  Change (BalanceDelta):                                  │
│  amount0: -1 ETH      (Pool gave ETH)                    │
│  amount1: +1800 USDC  (Pool gained USDC)                 │
│                                                          │
│  After:                                                  │
│  Reserve0: 1000 ETH   (decreased)                        │
│  Reserve1: 1,800,000 USDC (increased)                    │
└──────────────────────────────────────────────────────────┘
```

### 💡 Memory Trick

```
┌────────────────────────────────────────────────────────┐
│  How to Remember:                                      │
│                                                        │
│  zeroForOne = true                                     │
│  "Zero FOR One"                                        │
│  "Token ZERO FOR Token ONE"                            │
│  Token0 → Token1                                       │
│                                                        │
│  zeroForOne = false                                    │
│  "NOT Zero for One"                                    │
│  "One FOR Zero"                                        │
│  Token1 → Token0                                       │
└────────────────────────────────────────────────────────┘
```

### 🎨 Color-Coded Visualization

```
Pool: ETH/USDC

zeroForOne = TRUE:
  🟦 ETH (Token0)  ──────→  🟩 USDC (Token1)
  Input                     Output
  Amount0 increases         Amount1 decreases
  (+)                       (-)

zeroForOne = FALSE:
  🟦 ETH (Token0)  ←──────  🟩 USDC (Token1)
  Output                    Input
  Amount0 decreases         Amount1 increases
  (-)                       (+)
```

### 📝 Code Example in Hook

```solidity
function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    // Determine which direction the swap went
    if (params.zeroForOne) {
        // User swapped Token0 → Token1
        // amount0 will be positive (pool received Token0)
        // amount1 will be negative (pool gave Token1)

        int128 token0In = delta.amount0();   // Positive
        int128 token1Out = -delta.amount1(); // Make positive

        console.log("Swapped %d Token0 for %d Token1", token0In, token1Out);
    } else {
        // User swapped Token1 → Token0
        // amount1 will be positive (pool received Token1)
        // amount0 will be negative (pool gave Token0)

        int128 token1In = delta.amount1();   // Positive
        int128 token0Out = -delta.amount0(); // Make positive

        console.log("Swapped %d Token1 for %d Token0", token1In, token0Out);
    }

    return (BaseHook.afterSwap.selector, 0);
}
```

**Summary:**
- ✅ `zeroForOne = true` → Swap Token0 for Token1
- ✅ `zeroForOne = false` → Swap Token1 for Token0
- 💱 The currencies indeed swap based on this flag!

---

## Question 10: Understanding Negative Deltas
### "delta.amount0() is negative right? Since we set zeroForOne true and we swap token0 for token1?"

**Almost correct, but opposite!** When `zeroForOne = true`, `delta.amount0()` is actually **positive**, not negative. Let me explain why this is confusing at first.

### 🧠 The Mental Model: Pool's Perspective

```
KEY INSIGHT:
BalanceDelta shows changes FROM THE POOL'S PERSPECTIVE
Not from the user's perspective!

┌──────────────────────────────────────────────────────┐
│  User's View (What you might think):                 │
│  "I'm giving away Token0, so amount0 is negative"    │
│                                                      │
│  Pool's View (What BalanceDelta actually shows):     │
│  "I'm receiving Token0, so amount0 is positive"      │
└──────────────────────────────────────────────────────┘
```

### 📊 Visual Example: zeroForOne = true

```
SWAP: 1 ETH → 1800 USDC (zeroForOne = true)

User's Perspective:
┌────────────────────────────────────────┐
│  User (Alice)                          │
│  Before:  10 ETH, 0 USDC               │
│  After:   9 ETH, 1800 USDC             │
│                                        │
│  Change for Alice:                     │
│  ETH:  -1     (gave away)              │
│  USDC: +1800  (received)               │
└────────────────────────────────────────┘
        │ Transfers
        ▼
┌────────────────────────────────────────┐
│  Pool                                  │
│  Before:  1000 ETH, 1,800,000 USDC     │
│  After:   1001 ETH, 1,798,200 USDC     │
│                                        │
│  Change for Pool:                      │
│  ETH:  +1     (received) ◄─────────┐   │
│  USDC: -1800  (gave away)          │   │
│                                    │   │
│  BalanceDelta:                     │   │
│  amount0 = +1 ✓ ───────────────────┘   │
│  amount1 = -1800 ✓                     │
└────────────────────────────────────────┘

The BalanceDelta represents the POOL's change!
```

### 🔄 Both Directions Explained

```
DIRECTION 1: zeroForOne = true
┌──────────────────────────────────────────────────────┐
│  Trade: Token0 → Token1                              │
│                                                      │
│  User:                                               │
│  • Sends Token0 (gives)                              │
│  • Receives Token1 (gets)                            │
│                                                      │
│  Pool:                                               │
│  • Receives Token0 (amount0 INCREASES) → Positive ✓  │
│  • Sends Token1 (amount1 DECREASES) → Negative ✓     │
│                                                      │
│  BalanceDelta:                                       │
│  • amount0 = POSITIVE (e.g., +1e18)                  │
│  • amount1 = NEGATIVE (e.g., -1800e6)                │
└──────────────────────────────────────────────────────┘

DIRECTION 2: zeroForOne = false
┌──────────────────────────────────────────────────────┐
│  Trade: Token1 → Token0                              │
│                                                      │
│  User:                                               │
│  • Sends Token1 (gives)                              │
│  • Receives Token0 (gets)                            │
│                                                      │
│  Pool:                                               │
│  • Sends Token0 (amount0 DECREASES) → Negative ✓     │
│  • Receives Token1 (amount1 INCREASES) → Positive ✓  │
│                                                      │
│  BalanceDelta:                                       │
│  • amount0 = NEGATIVE (e.g., -1e18)                  │
│  • amount1 = POSITIVE (e.g., +1800e6)                │
└──────────────────────────────────────────────────────┘
```

### 🏦 Bank Account Analogy

```
Think of the Pool as a bank account:

Your Bank Account:
┌────────────────────────────────────────┐
│  You deposit $100                      │
│  Your balance change: +$100            │
│  (You received money)                  │
│                                        │
│  You withdraw $50                      │
│  Your balance change: -$50             │
│  (You gave money)                      │
└────────────────────────────────────────┘

Pool's Token0 Account:
┌────────────────────────────────────────┐
│  User swaps Token0 → Token1            │
│  (zeroForOne = true)                   │
│                                        │
│  Pool receives Token0                  │
│  Pool's Token0 balance change: +1 ETH  │
│  → amount0 = POSITIVE ✓                │
│                                        │
│  Pool sends Token1                     │
│  Pool's Token1 balance change: -1800 USDC │
│  → amount1 = NEGATIVE ✓                │
└────────────────────────────────────────┘
```

### 💻 Code Example with Real Values

```solidity
function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    // Example: User swaps 1 ETH → ? USDC (zeroForOne = true)

    int128 amount0 = delta.amount0();  // What's this value?
    int128 amount1 = delta.amount1();  // What's this value?

    if (params.zeroForOne) {
        // User sent ETH, received USDC

        console.log("amount0:", amount0);  // Output: amount0: 1000000000000000000 (1e18, POSITIVE!)
        console.log("amount1:", amount1);  // Output: amount1: -1800000000 (-1800e6, NEGATIVE!)

        // Pool RECEIVED Token0 (ETH) → Positive
        require(amount0 > 0, "amount0 should be positive");

        // Pool SENT Token1 (USDC) → Negative
        require(amount1 < 0, "amount1 should be negative");

        // To get the actual amounts traded (as positive numbers):
        uint256 ethReceived = uint256(uint128(amount0));  // 1 ETH
        uint256 usdcSent = uint256(uint128(-amount1));    // 1800 USDC
    } else {
        // User sent USDC, received ETH

        console.log("amount0:", amount0);  // Output: amount0: -1000000000000000000 (-1e18, NEGATIVE!)
        console.log("amount1:", amount1);  // Output: amount1: 1800000000 (1800e6, POSITIVE!)

        // Pool SENT Token0 (ETH) → Negative
        require(amount0 < 0, "amount0 should be negative");

        // Pool RECEIVED Token1 (USDC) → Positive
        require(amount1 > 0, "amount1 should be positive");

        // To get the actual amounts traded:
        uint256 ethSent = uint256(uint128(-amount0));     // 1 ETH
        uint256 usdcReceived = uint256(uint128(amount1)); // 1800 USDC
    }

    return (BaseHook.afterSwap.selector, 0);
}
```

### 📐 Sign Convention Table

```
┌───────────────┬──────────────┬───────────┬───────────┐
│ zeroForOne    │ Direction    │ amount0   │ amount1   │
├───────────────┼──────────────┼───────────┼───────────┤
│ true          │ Token0→Token1│ POSITIVE ✓│ NEGATIVE ✓│
│               │ (e.g.,ETH→USDC)│ (received)│ (sent)    │
├───────────────┼──────────────┼───────────┼───────────┤
│ false         │ Token1→Token0│ NEGATIVE ✓│ POSITIVE ✓│
│               │(e.g.,USDC→ETH)│ (sent)    │ (received)│
└───────────────┴──────────────┴───────────┴───────────┘

Rule of thumb:
• The token being SOLD → Pool receives → POSITIVE delta
• The token being BOUGHT → Pool sends → NEGATIVE delta
```

### 🎯 Common Confusion Points

```
❌ WRONG THINKING:
"I'm swapping Token0, so I'm losing Token0,
 so amount0 should be negative"

This is USER perspective!

✅ CORRECT THINKING:
"I'm swapping Token0, so the POOL receives Token0,
 so amount0 (from pool's view) is POSITIVE"

This is POOL perspective!

Why pool perspective?
• BalanceDelta represents state change of the pool
• Pool is the entity tracking its own reserves
• Your hook is querying the pool's balance change
• User's change is the opposite of pool's change
```

### 🔍 Practical Usage in Hooks

```solidity
// Example: Track volume for each direction

mapping(PoolId => uint256) public token0ToToken1Volume;
mapping(PoolId => uint256) public token1ToToken0Volume;

function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    PoolId poolId = key.toId();

    if (params.zeroForOne) {
        // amount0 is POSITIVE (pool received)
        // amount1 is NEGATIVE (pool sent)

        uint256 volumeIn = uint256(uint128(delta.amount0()));  // What pool received
        token0ToToken1Volume[poolId] += volumeIn;
    } else {
        // amount0 is NEGATIVE (pool sent)
        // amount1 is POSITIVE (pool received)

        uint256 volumeIn = uint256(uint128(delta.amount1()));  // What pool received
        token1ToToken0Volume[poolId] += volumeIn;
    }

    return (BaseHook.afterSwap.selector, 0);
}
```

### 🎓 Summary

```
┌──────────────────────────────────────────────────────┐
│  Key Takeaways:                                      │
│                                                      │
│  1. BalanceDelta is from the POOL's perspective      │
│     not the user's perspective                       │
│                                                      │
│  2. When zeroForOne = true:                          │
│     • amount0 = POSITIVE (pool receives Token0)      │
│     • amount1 = NEGATIVE (pool sends Token1)         │
│                                                      │
│  3. When zeroForOne = false:                         │
│     • amount0 = NEGATIVE (pool sends Token0)         │
│     • amount1 = POSITIVE (pool receives Token1)      │
│                                                      │
│  4. The sign convention:                             │
│     • POSITIVE = Pool balance increased              │
│     • NEGATIVE = Pool balance decreased              │
│                                                      │
│  5. To get user's perspective:                       │
│     • Flip the signs!                                │
│     • If pool gained (+), user lost (-)              │
│     • If pool lost (-), user gained (+)              │
└──────────────────────────────────────────────────────┘
```

### 🔄 Quick Reference Diagram

```
                    zeroForOne = true
     User                                  Pool
     ┌──────────┐                    ┌──────────┐
     │  Token0  │ ───────────────→   │  Token0  │
     │  (-1)    │      Sends         │  (+1) ✓  │  amount0 = POSITIVE
     └──────────┘                    └──────────┘
     ┌──────────┐                    ┌──────────┐
     │  Token1  │   ←───────────────  │  Token1  │
     │  (+1800) │      Receives       │  (-1800)✓│  amount1 = NEGATIVE
     └──────────┘                    └──────────┘


                    zeroForOne = false
     User                                  Pool
     ┌──────────┐                    ┌──────────┐
     │  Token0  │   ←───────────────  │  Token0  │
     │  (+1)    │      Receives       │  (-1) ✓  │  amount0 = NEGATIVE
     └──────────┘                    └──────────┘
     ┌──────────┐                    ┌──────────┐
     │  Token1  │ ───────────────→   │  Token1  │
     │  (-1800) │      Sends         │  (+1800)✓│  amount1 = POSITIVE
     └──────────┘                    └──────────┘

             BalanceDelta shows the POOL column!
```

---

## 📚 Further Reading

- [Uniswap v4 Documentation](https://docs.uniswap.org/contracts/v4/overview)
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)

---

*This FAQ is a living document. As you learn more, add your own questions and insights!*
