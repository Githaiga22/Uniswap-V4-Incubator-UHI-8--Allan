# Hook Mechanics - The Technical Magic Behind Hooks

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## 🎓 Hook Address Bitmap - The Clever Trick

**One-line**: The PoolManager knows which hook functions exist by reading specific bits in the hook contract's address itself.

**Simple Explanation**:
Imagine you have a phone number that secretly contains information:

```
Phone: (555) 123-4567

If 3rd digit is ODD  → Speaks Spanish
If 5th digit is EVEN → Has voicemail
If 7th digit is 5+   → Available after 5pm
```

Just by looking at the phone number, you know the person's capabilities!

Similarly, a hook's **address** contains hidden information about which functions it implements.

---

## 🌍 Real-World Analogy: License Plates

### Regular System (Naive Approach)
```
You see a car and want to know: "Can it carry cargo?"

Naive way:
1. Stop the car
2. Ask the driver
3. Check the trunk
4. Test if cargo fits

This is SLOW and requires interaction!
```

### Address Bitmap System (Smart Approach)
```
License Plate: ABC-1234

If last digit is EVEN → Sedan (no cargo)
If last digit is ODD  → Truck (can carry cargo)

Plate: ABC-1234 → Last digit 4 (even) → Sedan!
Plate: XYZ-5678 → Last digit 8 (even) → Sedan!
Plate: DEF-3579 → Last digit 9 (odd)  → Truck!

You know INSTANTLY just by looking at the plate!
```

---

## 🎨 Visual: What is a Bitmap?

A bitmap is just a series of true/false flags stored as bits:

```
Regular Boolean Variables (Expensive):
┌────────────────────────────────────┐
│ hasBeforeSwap: true                │  (1 storage slot)
│ hasAfterSwap: false                │  (1 storage slot)
│ hasBeforeAdd: true                 │  (1 storage slot)
│ hasAfterAdd: false                 │  (1 storage slot)
└────────────────────────────────────┘
Total: 4 storage slots = EXPENSIVE!

Bitmap (Efficient):
┌────────────────────────────────────┐
│ Features: 0b1010                   │  (1 storage slot)
│           ││││                     │
│           │││└─ hasAfterAdd: 0    │
│           ││└── hasBeforeAdd: 1   │
│           │└─── hasAfterSwap: 0   │
│           └──── hasBeforeSwap: 1  │
└────────────────────────────────────┘
Total: 1 storage slot = CHEAP!
```

---

## 💻 Understanding Binary Addresses

Ethereum addresses are 20 bytes (160 bits). Each bit can be 0 or 1.

### Example Address Breakdown
```
Address: 0x0000000000000000000000000000000000000090

In Hexadecimal (base 16):
0x 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 90

In Binary (base 2):
Last byte (0x90) = 1001 0000

Bit-by-bit (right to left):
Bit 1: 0
Bit 2: 0
Bit 3: 0
Bit 4: 0
Bit 5: 1  ← This is ON!
Bit 6: 0
Bit 7: 0
Bit 8: 1  ← This is ON!
```

---

## 🎨 Visual: Hook Flags

Each hook function corresponds to a specific bit in the address:

```
┌───────────────────────────────────────────────────────────┐
│  ETHEREUM ADDRESS (160 bits)                              │
├───────────────────────────────────────────────────────────┤
│                                                            │
│  Bit 14: BEFORE_INITIALIZE_FLAG                           │
│  Bit 13: AFTER_INITIALIZE_FLAG                            │
│  Bit 12: BEFORE_ADD_LIQUIDITY_FLAG                        │
│  Bit 11: AFTER_ADD_LIQUIDITY_FLAG                         │
│  Bit 10: BEFORE_REMOVE_LIQUIDITY_FLAG                     │
│  Bit 9:  AFTER_REMOVE_LIQUIDITY_FLAG                      │
│  Bit 8:  BEFORE_SWAP_FLAG                                 │
│  Bit 7:  AFTER_SWAP_FLAG                                  │
│  Bit 6:  BEFORE_DONATE_FLAG                               │
│  Bit 5:  AFTER_DONATE_FLAG                                │
│  Bit 4:  BEFORE_SWAP_RETURNS_DELTA_FLAG                   │
│  Bit 3:  AFTER_SWAP_RETURNS_DELTA_FLAG                    │
│  Bit 2:  AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG           │
│  Bit 1:  AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG        │
│                                                            │
│  Bit = 1 → Function EXISTS                                │
│  Bit = 0 → Function DOESN'T EXIST                         │
└───────────────────────────────────────────────────────────┘
```

---

## 💡 Example: Decoding a Hook Address

Let's say we have a hook that implements:
- `beforeSwap`
- `afterSwap`
- `afterDonate`

### Step 1: Identify Required Bits
```
beforeSwap  → Bit 8
afterSwap   → Bit 7
afterDonate → Bit 5
```

### Step 2: Create Binary Pattern
```
Bit 14: 0 (no beforeInitialize)
Bit 13: 0 (no afterInitialize)
Bit 12: 0 (no beforeAddLiquidity)
Bit 11: 0 (no afterAddLiquidity)
Bit 10: 0 (no beforeRemoveLiquidity)
Bit 9:  0 (no afterRemoveLiquidity)
Bit 8:  1 (YES beforeSwap) ✓
Bit 7:  1 (YES afterSwap) ✓
Bit 6:  0 (no beforeDonate)
Bit 5:  1 (YES afterDonate) ✓
Bit 4:  0 (no beforeSwapReturnsDelta)
...rest are 0

Binary (bits 14-1): 00 0000 1110 0000
                           ^^^
                           Our hooks!
```

### Step 3: Find Address Ending in That Pattern
```
Need address where bits 5, 7, 8 are set to 1:

In hex, that's: ...00E0 or similar

Example valid address:
0x0000000000000000000000000000000000000E0

This address "signals" it has beforeSwap, afterSwap, afterDonate!
```

---

## 🎨 Visual: The Checking Process

```
USER TRIES TO SWAP
        │
        ▼
┌───────────────────────┐
│  PoolManager checks   │
│  "Does hook have      │
│   beforeSwap?"        │
└───────┬───────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  Read hook address:                 │
│  0x...00E0                          │
│                                     │
│  Convert to binary:                 │
│  ...0000 1110 0000                  │
│         ^^^                         │
│  Check bit 8: 1 ✓                   │
│                                     │
│  Result: YES, beforeSwap exists!    │
└────────┬────────────────────────────┘
         │
         ▼
┌───────────────────────┐
│  Call hook.beforeSwap │
└───────────────────────┘
```

---

## 🔧 How PoolManager Checks Flags

In the actual V4 code:

```solidity
library Hooks {
    // Flag values (bit positions)
    uint256 constant BEFORE_SWAP_FLAG = 1 << 8;  // Bit 8
    uint256 constant AFTER_SWAP_FLAG = 1 << 7;   // Bit 7

    // Check if hook has beforeSwap
    function hasPermission(address hook, uint256 flag)
        internal pure returns (bool) {
        return uint256(uint160(hook)) & flag != 0;
    }
}

// Usage:
if (Hooks.hasPermission(hookAddress, BEFORE_SWAP_FLAG)) {
    // Call beforeSwap
    hook.beforeSwap(...);
}
```

**What's happening?**
- `uint256(uint160(hook))`: Convert address to number
- `& flag`: Bitwise AND operation (checks if bit is set)
- `!= 0`: If result is non-zero, bit is set!

---

## 🎨 Visual: Bitwise AND Operation

```
Hook Address (as binary): 0000 1110 0000
BEFORE_SWAP_FLAG:         0001 0000 0000 (bit 8)
                          ─────────────────
                AND →     0000 0000 0000 = 0  ❌ (No beforeSwap)

Wait, wrong example! Let me fix:

Hook Address (as binary): 0000 1110 0000
                               ^^^
                          Bit 8 is 1!

BEFORE_SWAP_FLAG:         0001 0000 0000
                          ─────────────────
                AND →     0001 0000 0000 ≠ 0  ✅ (Has beforeSwap!)
```

---

## 🏭 Address Mining - How Do You Get The Right Address?

**Problem**: You can't just "pick" your deployment address. It's determined by:
```
address = hash(deployer, nonce)
```

**Solution**: Try many times until you get a lucky address!

### Mining Process
```
1. Generate a deployment transaction
2. Calculate what address it would deploy to
3. Check if address has correct bits
4. If YES → Deploy!
   If NO → Change salt/nonce and try again
```

### Example Mining Loop
```solidity
for (uint256 salt = 0; salt < type(uint256).max; salt++) {
    address predictedAddress = computeAddress(bytecode, salt);

    if (hasCorrectFlags(predictedAddress)) {
        // Found it! Deploy with this salt
        deploy(bytecode, salt);
        break;
    }
}
```

**How long does it take?**
- For a few flags: Seconds to minutes
- For many flags: Could be hours!
- For ALL flags: Astronomically unlikely

---

## 🎨 Visual: The Mining Process

```
MINING FOR CORRECT ADDRESS
═══════════════════════════

Want: beforeSwap + afterSwap (bits 7 & 8 set)

Try 1: salt = 0x0001
  ↓
  Predicted address: 0x...1234
  Binary: ...0001 0011 0100
  Bits 7&8: 00 ❌
  Keep trying...

Try 2: salt = 0x0002
  ↓
  Predicted address: 0x...5678
  Binary: ...0101 0110 1000
  Bits 7&8: 01 ❌
  Keep trying...

...

Try 157: salt = 0x009D
  ↓
  Predicted address: 0x...01E0
  Binary: ...0001 1110 0000
  Bits 7&8: 11 ✅
  FOUND IT! Deploy with salt 0x009D!
```

---

## ⚠️ Important: Addresses Can Lie!

**Problem**: An address might CLAIM to have a function (bit set to 1) but actually doesn't implement it.

```
Address: 0x...01E0
Binary bits show: beforeSwap = 1 ✅

But actual contract:
contract BadHook {
    // Oops! Forgot to implement beforeSwap!
}

What happens?
→ PoolManager tries to call beforeSwap()
→ Function doesn't exist
→ Transaction REVERTS
→ Pool is unusable!
```

**Protection**:
1. **Test thoroughly** before deploying to mainnet
2. **Verify** address bits match implementation
3. **Community review** of popular hooks
4. Users avoid suspicious hooks

---

## 🔗 Where Are Flags Defined?

All flags are in the Hooks library:

```solidity
library Hooks {
    uint256 internal constant BEFORE_INITIALIZE_FLAG = 1 << 14;
    uint256 internal constant AFTER_INITIALIZE_FLAG = 1 << 13;
    uint256 internal constant BEFORE_ADD_LIQUIDITY_FLAG = 1 << 12;
    uint256 internal constant AFTER_ADD_LIQUIDITY_FLAG = 1 << 11;
    uint256 internal constant BEFORE_REMOVE_LIQUIDITY_FLAG = 1 << 10;
    uint256 internal constant AFTER_REMOVE_LIQUIDITY_FLAG = 1 << 9;
    uint256 internal constant BEFORE_SWAP_FLAG = 1 << 8;
    uint256 internal constant AFTER_SWAP_FLAG = 1 << 7;
    uint256 internal constant BEFORE_DONATE_FLAG = 1 << 6;
    uint256 internal constant AFTER_DONATE_FLAG = 1 << 5;
    uint256 internal constant BEFORE_SWAP_RETURNS_DELTA_FLAG = 1 << 4;
    uint256 internal constant AFTER_SWAP_RETURNS_DELTA_FLAG = 1 << 3;
    uint256 internal constant AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 2;
    uint256 internal constant AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG = 1 << 1;
}
```

---

## 📊 Why This Design?

### Advantages:
```
✅ No storage needed for flags
✅ Instant checking (no external calls)
✅ Gas efficient
✅ Clever and elegant
✅ Permissionless (anyone can deploy)
```

### Disadvantages:
```
❌ Addresses can lie
❌ Need to mine correct address
❌ Can't change hooks after deployment
❌ Confusing for beginners
```

**Verdict**: The gas savings and elegance are worth the complexity!

---

## 🔗 Resources & Citations

1. **Atrium Academy - Hook Address Bitmap**
   https://learn.atrium.academy/course/4b6c25df-f4c8-4b92-ab38-a930284d237e/technical-introduction/v4-hooks

2. **Uniswap V4 Hooks.sol Library**
   https://github.com/Uniswap/v4-core/blob/main/src/libraries/Hooks.sol

3. **Understanding Bitwise Operations**
   https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Bitwise_AND

4. **CREATE2 Address Prediction**
   https://docs.openzeppelin.com/cli/2.8/deploying-with-create2

---

## ✅ Quick Self-Check

1. **What does the hook address bitmap tell us?**
   <details>
   <summary>Answer</summary>
   Which hook functions are implemented in the contract, encoded as bits in the address itself.
   </details>

2. **How does the PoolManager check if a hook has beforeSwap?**
   <details>
   <summary>Answer</summary>
   It checks if bit 8 of the hook's address is set to 1 using a bitwise AND operation.
   </details>

3. **What is address mining?**
   <details>
   <summary>Answer</summary>
   The process of trying different deployment salts until you find an address with the correct bits set for your hook functions.
   </details>

4. **Can an address lie about which functions it has?**
   <details>
   <summary>Answer</summary>
   Yes! An address might have certain bits set but not actually implement those functions. This will cause transactions to revert.
   </details>

5. **Why use a bitmap instead of storing boolean flags?**
   <details>
   <summary>Answer</summary>
   It's much more gas efficient - no storage reads needed, just check the address bits directly.
   </details>

---

**Previous**: [Hooks Introduction](./06-hooks-introduction.md)
**Next**: [Swap Flow](./08-swap-flow.md)
