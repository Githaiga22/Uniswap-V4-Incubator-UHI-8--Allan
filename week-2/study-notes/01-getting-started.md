# Getting Started with Your First Uniswap v4 Hook

Welcome! This guide will walk you through understanding, testing, and modifying your first Uniswap v4 hook.

## 📁 Project Structure

```
Build your first hook/
├── src/
│   ├── MyFirstHook.sol      # Simple example: counts swaps
│   └── PointsHook.sol       # Advanced: awards points for actions
├── test/
│   ├── MyFirstHook.t.sol    # Tests for MyFirstHook
│   ├── PointsHook.t.sol     # Tests for PointsHook
│   └── utils/
│       └── HookMiner.sol    # Utility to find correct hook addresses
├── script/
│   └── DeployHook.s.sol     # Deployment script
├── lib/                      # Dependencies (installed via forge)
│   ├── forge-std/           # Foundry standard library
│   ├── v4-core/             # Uniswap v4 core contracts
│   └── v4-periphery/        # Uniswap v4 periphery contracts
├── foundry.toml             # Foundry configuration
├── FAQ.md                   # Answers to common questions
└── GETTING_STARTED.md       # This file!
```

## 🚀 Quick Start

### 1. Verify Installation

```bash
# Check that everything built successfully
forge build

# You should see: "Compiler run successful"
```

### 2. Run the Tests

```bash
# Run all tests
forge test

# Run with verbose output to see details
forge test -vv

# Run specific test file
forge test --match-path test/PointsHook.t.sol

# Run specific test function
forge test --match-test testSwapAwardsPoints
```

Expected output:
```
Running 6 tests for test/PointsHook.t.sol:PointsHookTest
[PASS] testAddLiquidityAwardsPoints() (gas: 234156)
[PASS] testCombinedActions() (gas: 345678)
[PASS] testMultipleSwapsAccumulatePoints() (gas: 456789)
[PASS] testPointsArePerUser() (gas: 234567)
[PASS] testSwapAwardsPoints() (gas: 123456)
```

### 3. Explore the Code

Start with the simplest example and work your way up:

```
1. src/MyFirstHook.sol         (Beginner)
   ↓
2. src/PointsHook.sol          (Intermediate)
   ↓
3. test/PointsHook.t.sol       (Learn testing)
   ↓
4. Create your own hook!       (Advanced)
```

## 📖 Understanding PointsHook

Let's walk through the key parts of `PointsHook.sol`:

### Hook Permissions

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        // We only enable the hooks we need:
        afterSwap: true,              // ✓ Track swaps
        afterAddLiquidity: true,      // ✓ Track liquidity
        // All others: false
    });
}
```

**What this means:**
- Our hook will be called AFTER swaps and liquidity additions
- We don't interfere with other operations
- The hook address must have the correct bits set (more in FAQ.md)

### Awarding Points After Swaps

```solidity
function _afterSwap(
    address sender,               // Who made the swap
    PoolKey calldata key,        // Which pool
    SwapParams calldata params,  // Swap details
    BalanceDelta delta,          // Amount changes
    bytes calldata hookData      // Custom data
) internal override returns (bytes4, int128) {
    PoolId poolId = key.toId();

    // Award points
    userPoints[sender][poolId] += POINTS_PER_SWAP;

    // Track stats
    totalSwaps[poolId]++;

    // Return selector to confirm success
    return (BaseHook.afterSwap.selector, 0);
}
```

**What happens:**
1. User swaps in a pool
2. PoolManager calls our `_afterSwap` function
3. We award points to the user
4. We return a selector to confirm execution

### Querying Points

```solidity
function getPoints(address user, PoolId poolId) external view returns (uint256) {
    return userPoints[user][poolId];
}
```

**Usage:**
```solidity
uint256 myPoints = pointsHook.getPoints(myAddress, poolId);
console.log("I have", myPoints, "points!");
```

## 🧪 Understanding Tests

Let's break down a test from `PointsHook.t.sol`:

### Test Setup

```solidity
function setUp() public {
    // 1. Deploy Uniswap v4 core contracts
    deployFreshManagerAndRouters();

    // 2. Mine correct hook address
    uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG);
    (address hookAddress, bytes32 salt) = HookMiner.find(...);

    // 3. Deploy hook with mined salt
    hook = new PointsHook{salt: salt}(IPoolManager(address(manager)));

    // 4. Initialize test pool
    (key,) = initPool(currency0, currency1, hook, 3000, SQRT_PRICE_1_1);

    // 5. Add liquidity
    modifyLiquidityRouter.modifyLiquidity(key, LIQUIDITY_PARAMS, ZERO_BYTES);
}
```

### A Simple Test

```solidity
function testSwapAwardsPoints() public {
    PoolId poolId = key.toId();

    // Act as Alice
    vm.startPrank(alice);

    // Perform a swap
    swap(key, true, -1e18, ZERO_BYTES);

    vm.stopPrank();

    // Check points were awarded
    uint256 points = hook.getPoints(alice, poolId);
    assertEq(points, hook.POINTS_PER_SWAP());
}
```

**What's happening:**
1. `vm.startPrank(alice)` - Pretend to be Alice
2. `swap(...)` - Alice swaps tokens
3. `vm.stopPrank()` - Stop being Alice
4. `assertEq(...)` - Verify Alice got points

## 🎯 Exercise: Modify the Hook

Let's make some changes to learn!

### Exercise 1: Change Point Values

**Task:** Double the points for swapping

```solidity
// In PointsHook.sol, change:
uint256 public constant POINTS_PER_SWAP = 10;

// To:
uint256 public constant POINTS_PER_SWAP = 20;
```

Then test:
```bash
forge test --match-test testSwapAwardsPoints -vv
```

The test should now fail! Why? The test expects 10 points, but we're awarding 20.

**Fix the test:**
```solidity
// In PointsHook.t.sol, the assertion already uses:
assertEq(points, hook.POINTS_PER_SWAP());
// This automatically uses the new value! No change needed.
```

### Exercise 2: Add Bonus Points for Large Swaps

**Task:** Award 2x points for swaps larger than 1 token

```solidity
function _afterSwap(
    address sender,
    PoolKey calldata key,
    SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    PoolId poolId = key.toId();

    // Base points
    uint256 pointsToAward = POINTS_PER_SWAP;

    // Bonus for large swaps!
    int128 swapAmount = delta.amount0();
    if (swapAmount < 0) swapAmount = -swapAmount; // Get absolute value

    if (uint256(uint128(swapAmount)) > 1 ether) {
        pointsToAward *= 2; // Double points!
    }

    userPoints[sender][poolId] += pointsToAward;
    totalSwaps[poolId]++;

    return (BaseHook.afterSwap.selector, 0);
}
```

**Write a test:**
```solidity
function testLargeSwapBonusPoints() public {
    PoolId poolId = key.toId();

    vm.startPrank(alice);

    // Small swap (1 token)
    swap(key, true, -1e18, ZERO_BYTES);
    uint256 pointsSmall = hook.getPoints(alice, poolId);

    // Large swap (5 tokens)
    swap(key, false, 5e18, ZERO_BYTES);
    uint256 pointsLarge = hook.getPoints(alice, poolId);

    vm.stopPrank();

    // Large swap should give more points
    assertEq(pointsLarge - pointsSmall, hook.POINTS_PER_SWAP() * 2);
}
```

### Exercise 3: Add a Leaderboard

**Task:** Create a function to get top users by points

```solidity
// Add to PointsHook.sol

// New state variable
address[] public allUsers;
mapping(address => bool) private hasUserSwapped;

// Modify _afterSwap to track users
function _afterSwap(...) internal override returns (bytes4, int128) {
    PoolId poolId = key.toId();

    // Track new users
    if (!hasUserSwapped[sender]) {
        allUsers.push(sender);
        hasUserSwapped[sender] = true;
    }

    userPoints[sender][poolId] += POINTS_PER_SWAP;
    totalSwaps[poolId]++;

    return (BaseHook.afterSwap.selector, 0);
}

// New function: Get top 3 users
function getTop3(PoolId poolId) external view returns (
    address[3] memory topUsers,
    uint256[3] memory topPoints
) {
    // Simple bubble sort (ok for small arrays)
    for (uint i = 0; i < allUsers.length && i < 3; i++) {
        address topUser = allUsers[0];
        uint256 topPoint = userPoints[allUsers[0]][poolId];

        for (uint j = 1; j < allUsers.length; j++) {
            if (userPoints[allUsers[j]][poolId] > topPoint) {
                topUser = allUsers[j];
                topPoint = userPoints[allUsers[j]][poolId];
            }
        }

        topUsers[i] = topUser;
        topPoints[i] = topPoint;
    }
}
```

## 🔧 Common Operations

### Compile Code
```bash
forge build
```

### Run Tests
```bash
# All tests
forge test

# Verbose (shows console.log output)
forge test -vv

# Very verbose (shows trace)
forge test -vvvv

# Specific test
forge test --match-test testSwapAwardsPoints
```

### Clean Build Artifacts
```bash
forge clean
```

### Format Code
```bash
forge fmt
```

### Check Gas Usage
```bash
forge test --gas-report
```

### Generate Coverage Report
```bash
forge coverage
```

## 🐛 Troubleshooting

### "Hook address mismatch"
```
Error: Hook address mismatch
```

**Solution:** The HookMiner didn't find a valid salt. This is rare but can happen.
- Increase MAX_LOOP in HookMiner.sol
