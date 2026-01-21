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

