# Quiz 1: Uniswap V4 Architecture & Hooks - Answer Key

**Date**: January 20, 2026 (Week 1)

---

## Question 1: Singleton PoolManager

**What is the primary reason Uniswap v4 uses a singleton PoolManager instead of deploying a new contract per pool like v3?**

### ✅ Answer: C - To lower gas costs and improve composability

### Why?

```
V3 (Multiple Contracts):
┌─────┐  ┌─────┐  ┌─────┐
│Pool1│  │Pool2│  │Pool3│
└─────┘  └─────┘  └─────┘
External calls = EXPENSIVE

V4 (Singleton):
┌─────────────────┐
│  PoolManager    │
│  ├─ Pool1       │
│  ├─ Pool2       │
│  └─ Pool3       │
└─────────────────┘
Internal calls = CHEAP
```

**Explanation**: Singleton design enables:
- Internal function calls (not external) = less gas
- Multi-hop swaps without moving tokens between contracts
- All pools share same infrastructure

**Why others are wrong**:
- A: Side effect, not primary reason
- B: Code readability isn't the goal
- D: Flash loans existed in V3 too

---

## Question 2: Flash Accounting

**What is the main benefit of Flash Accounting in v4?**

### ✅ Answer: C - Avoids intermediate token transfers in multi-hop swaps

### Why?

```
WITHOUT Flash Accounting (V3):
ETH → USDC → DAI

Step 1: Transfer ETH
Step 2: Transfer USDC ← (Extra transfer!)
Step 3: Transfer DAI

= 3 transfers

WITH Flash Accounting (V4):
ETH → USDC → DAI

Step 1: Transfer ETH
Step 2: [Math only, no transfer]
Step 3: Transfer DAI

= 2 transfers (USDC skipped!)
```

**Explanation**: Flash accounting tracks balance deltas internally. Intermediate tokens in a multi-hop swap never actually move - only start and end tokens transfer.

**Why others are wrong**:
- A: Can't do infinite swaps, still limited by balances
- B: Custom fees come from hooks, not flash accounting
- D: Batching happens at router level, not flash accounting

---

## Question 3: Transient Storage

**What EIP introduced transient storage and what is its key benefit?**

### ✅ Answer: C - EIP-1153; low-gas ephemeral storage

### Why?

```
Storage Types:

Permanent Storage:
Write: 20,000 gas
Read:   2,100 gas
Persists: Forever ✓

Transient Storage:
Write:    100 gas ✓✓✓
Read:     100 gas ✓✓✓
Persists: One transaction only

Perfect for temporary flags!
```

**Explanation**: EIP-1153 added TSTORE/TLOAD opcodes for cheap temporary storage. V4 uses it to track locks and deltas during a transaction, then auto-erases after.

**Why others are wrong**:
- A: EIP-3074 is about account abstraction
- B: EIP-4337 is also account abstraction
- D: EIP-721 is NFT standard

---

## Question 4: Hook Function Detection

**How does Uniswap v4 determine which hook functions a contract implements?**

### ✅ Answer: C - From bit flags encoded in the hook's contract address

### Why?

```
Hook Address: 0x...01E0

Binary: ...0001 1110 0000
               ││││
               │││└─ Bit 5: afterDonate ✓
               ││└── Bit 7: afterSwap ✓
               │└─── Bit 8: beforeSwap ✓
               └──── Bit 9: (not set)

Address = Capability Map!
```

**Explanation**: Each hook function corresponds to a specific bit in the address. PoolManager checks the address bits to know which functions to call.

**Why others are wrong**:
- A: No registration function needed
- B: Contract storage isn't used for this
- D: Not a mapping, it's in the address itself

---

## Question 5: Address Mining

**Why is address mining necessary when deploying hooks?**

### ✅ Answer: D - To embed hook capability flags in the address

### Why?

```
Mining Process:

Want: beforeSwap + afterSwap
Need: Bits 7 & 8 = 1

Try salt 1 → Address: 0x...1234
Binary: ...0001 0011 0100
Bits 7&8: 01 ❌

Try salt 2 → Address: 0x...5678
Binary: ...0101 0110 1000
Bits 7&8: 01 ❌

Try salt 157 → Address: 0x...01E0
Binary: ...0001 1110 0000
Bits 7&8: 11 ✅ FOUND!

Deploy with salt 157!
```

**Explanation**: You need an address where specific bits match your implemented functions. Mining tries different deployment salts until finding a matching address.

**Why others are wrong**:
- A: Collision avoidance isn't the goal
