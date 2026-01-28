# Project Structure - Uniswap v4 Hooks Workshop

This document explains the organization of this educational hook development project.

---

## 📁 Complete Directory Structure

```
Build your first hook/
│
├── 📚 Documentation
│   ├── README.md                    # Project overview
│   ├── PROJECT_STRUCTURE.md         # This file - explains organization
│   ├── GETTING_STARTED.md           # Tutorial and quick start
│   ├── CODE_WALKTHROUGH.md          # Line-by-line code explanations
│   └── FAQ.md                       # Common questions answered
│
├── 🔧 Configuration
│   ├── foundry.toml                 # Foundry configuration & remappings
│   └── .gitignore                   # Git ignore rules
│
├── 📦 Source Code (src/)
│   ├── examples/                    # 👨‍🎓 Educational hook examples
│   │   ├── MyFirstHook.sol         # Beginner: Simple swap counter
│   │   └── PointsHook.sol          # Advanced: Full points system
│   │
│   ├── base/                        # 🏗️ Base contracts (future: reusable)
│   │   └── (empty - for your extensions)
│   │
│   └── interfaces/                  # 📋 Custom interfaces (future)
│       └── (empty - for your extensions)
│
├── 🧪 Tests (test/)
│   ├── MyFirstHook.t.sol           # Tests for MyFirstHook
│   ├── PointsHook.t.sol            # Tests for PointsHook
│   └── utils/                       # Test utilities
│       └── HookMiner.sol           # Find valid hook addresses
│
├── 🚀 Scripts (script/)
│   └── DeployHook.s.sol            # Deployment script
│
├── 📚 Dependencies (lib/)
│   ├── forge-std/                   # Foundry standard library
│   ├── v4-core/                     # Uniswap v4 core contracts
│   │   ├── src/
│   │   │   ├── PoolManager.sol     # Main pool manager
│   │   │   ├── ERC6909.sol         # Token implementation
│   │   │   ├── ProtocolFees.sol    # Fee handling
│   │   │   ├── types/               # Core type definitions
│   │   │   │   ├── BalanceDelta.sol
│   │   │   │   ├── BeforeSwapDelta.sol
│   │   │   │   ├── Currency.sol
│   │   │   │   ├── PoolId.sol
│   │   │   │   ├── PoolKey.sol
│   │   │   │   └── PoolOperation.sol
│   │   │   ├── interfaces/          # Core interfaces
│   │   │   │   ├── IPoolManager.sol
│   │   │   │   └── IHooks.sol
│   │   │   └── libraries/           # Core libraries
│   │   │       └── Hooks.sol
│   │   └── test/
│   │       └── utils/
│   │           └── Deployers.sol   # Test helpers
│   │
│   └── v4-periphery/                # Uniswap v4 periphery contracts
│       └── src/
│           └── utils/
│               └── BaseHook.sol    # Base hook implementation
│
└── 🏗️ Build Artifacts (ignored in git)
    ├── out/                         # Compiled contracts
    └── cache/                       # Build cache
```

---

## 🎯 Understanding the Structure

### Our Code vs Dependencies

```
┌─────────────────────────────────────────────────────────────┐
│  YOUR CODE (you write and modify)                          │
│  ├── src/examples/          ← Hook implementations          │
│  ├── test/                  ← Tests for your hooks          │
│  └── script/                ← Deployment scripts            │
│                                                             │
│  DEPENDENCIES (installed, don't modify)                     │
│  └── lib/                                                   │
│      ├── v4-core/           ← Core Uniswap v4 contracts     │
│      ├── v4-periphery/      ← Helper contracts & BaseHook   │
│      └── forge-std/         ← Testing framework             │
└─────────────────────────────────────────────────────────────┘
```

### What Your Instructor is Showing

When your instructor shows files like:
- `PoolManager.sol`
- `ERC6909.sol`
- `types/BalanceDelta.sol`
- etc.

These are in **lib/v4-core/** - the Uniswap v4 core that we import!

```
┌────────────────────────────────────────────────────────┐
│  Instructor's Screen                                   │
│  └── uniswap-v4-core/          ← They're showing THIS  │
│      └── src/                                          │
│          ├── PoolManager.sol                           │
│          ├── types/                                    │
│          │   ├── BalanceDelta.sol                      │
│          │   └── PoolKey.sol                           │
│          └── ...                                       │
│                                                        │
│  Your Project                                          │
│  ├── src/examples/             ← You write hooks HERE  │
│  │   ├── MyFirstHook.sol                               │
│  │   └── PointsHook.sol                                │
│  └── lib/v4-core/              ← Same code as above!   │
│      └── src/                    (installed dependency)│
│          ├── PoolManager.sol                           │
│          └── types/                                    │
│              ├── BalanceDelta.sol                      │
│              └── PoolKey.sol                           │
└────────────────────────────────────────────────────────┘
```

---

## 📖 File-by-File Explanation

### Documentation Files

#### README.md
- Project overview
- What this project teaches
- Quick links to other docs

#### PROJECT_STRUCTURE.md (this file)
- Complete directory structure
- Explanation of organization
- How it relates to Uniswap v4 core

#### GETTING_STARTED.md
- Step-by-step tutorial
- Exercises to try
- Common commands
- Troubleshooting

#### CODE_WALKTHROUGH.md
- Line-by-line explanations
- ASCII diagrams
- Real-world analogies
- Detailed learning material

#### FAQ.md
- Answers to common questions
- Visual explanations
- Advanced topics

---

### Source Code (src/)

#### src/examples/
Contains educational hook implementations:

**MyFirstHook.sol**
```
Purpose: Beginner-friendly introduction
Features:
  • Simple swap counter
  • Demonstrates basic hook structure
  • Shows permission system
  • Minimal complexity
Hooks Used:
  • beforeSwap
  • afterSwap
```

**PointsHook.sol**
```
Purpose: Advanced, production-ready pattern
Features:
  • User-specific point tracking
  • Multiple hook types
  • View functions for queries
  • Extensive documentation
Hooks Used:
  • afterSwap
  • afterAddLiquidity
```

#### src/base/ (Empty - For Your Extensions)
Purpose: Reusable base contracts you create
```
Example future files:
  • BaseRewardHook.sol      - Common reward logic
  • BaseAccessControl.sol   - Whitelist/blacklist pattern
  • BaseOracle.sol          - Price oracle integration
```

#### src/interfaces/ (Empty - For Your Extensions)
Purpose: Custom interfaces for your hooks
```
Example future files:
  • IRewardCalculator.sol
