# Week 2: Key Learnings and Insights

**Author**: Allan Robinson
**Date**: January 27, 2026
**Instructor**: Tom Wade

---

## The Hook Development Mindset

Building hooks requires thinking differently than typical smart contract development. You're not building standalone logic - you're building plugins that integrate with an existing system.

```
Traditional Contract:        Hook Contract:
┌──────────────────┐        ┌──────────────────┐
│  Your logic      │        │   PoolManager    │
│  stands alone    │        │        ↓         │
│                  │        │   Your logic     │
│  Full control    │        │   (constrained)  │
└──────────────────┘        └──────────────────┘
```

**Key shift**: You operate within the PoolManager's execution context. This means:
- You don't see end users directly (`msg.sender` is always PoolManager)
- You can't control swap mechanics, only observe/react
- Your return values matter (selectors validate execution)
- Gas efficiency is critical (runs on every pool operation)

---

## Critical Technical Concepts

### 1. Permission-Encoded Addresses

The most non-obvious aspect of V4 hooks.

```
Your hook address: 0x1234...00C0
                            ^^^^
                            Binary: 0000 0000 1100 0000

Bit mapping:
Bit 6: beforeSwap = 1 (enabled)
Bit 7: afterSwap = 1 (enabled)
All others: 0 (disabled)

Result: Address MUST end in 0xC0
```

**Consequence**: Can't just deploy with `create()`. Must use `create2()` with salt mining to find valid addresses.

**HookMiner.sol**:
```solidity
// Brute force loop
for (uint256 salt = 0; salt < MAX_LOOP; salt++) {
    address computed = computeAddress(salt);
    if (hasCorrectBits(computed, permissions)) {
        return salt; // Found it!
    }
}
```

**Personal note**: This felt weird at first but makes sense. Gas-efficient permission validation without storage reads.

### 2. BaseHook Inheritance Pattern

The `BaseHook` abstract contract handles all boilerplate:
- Constructor takes `IPoolManager`
- Stores reference to manager
- Implements public `hookName()` functions that call your internal `_hookName()` functions
- Validates return selectors

```
Your responsibility:
