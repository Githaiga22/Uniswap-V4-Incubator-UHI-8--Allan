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
