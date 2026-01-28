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

