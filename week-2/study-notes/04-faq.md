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
