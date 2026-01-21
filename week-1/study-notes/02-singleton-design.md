# Singleton Design - One Contract to Rule Them All

**Date**: January 20, 2026 (Week 1 - Day 1)

---

## 🎓 What is the Singleton Design?

**One-line**: Instead of creating a new contract for each trading pool, V4 puts ALL pools inside ONE giant contract called the PoolManager.

**Simple Explanation**:
Think about a library. In the old system (V3), every book genre had its own separate building:
- Science fiction → Building A
- Mystery → Building B
- Romance → Building C

To read books from different genres, you'd have to walk between buildings (expensive!).

In the new system (V4), ALL books are in ONE massive library (PoolManager). You can grab a sci-fi book, a mystery, and a romance all in one trip. Much more efficient!

---

## 🌍 Real-World Analogy: Restaurant Evolution

### Uniswap V3: Food Truck Park
```
┌─────────┐  ┌─────────┐  ┌─────────┐
│  Taco   │  │  Pizza  │  │  Burger │
│  Truck  │  │  Truck  │  │  Truck  │
│  🌮     │  │  🍕     │  │  🍔     │
└─────────┘  └─────────┘  └─────────┘

Want tacos AND pizza?
→ Walk to Taco Truck (gas fee)
→ Walk to Pizza Truck (gas fee)
→ Each truck = separate business (expensive to set up)
```

### Uniswap V4: Food Court (Singleton)
```
┌─────────────────────────────────────────┐
│         FOOD COURT MANAGER              │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐   │
│  │ 🌮  │  │ 🍕  │  │ 🍔  │  │ 🍜  │   │
│  │Taco │  │Pizza│  │Brgr │  │Ramen│   │
│  └─────┘  └─────┘  └─────┘  └─────┘   │
│                                         │
│  All vendors in ONE location!           │
│  One payment counter!                   │
│  Shared infrastructure!                 │
└─────────────────────────────────────────┘

Want tacos AND pizza?
→ Walk to one counter, order both (one gas fee)
→ All operations share the same building (cheaper)
```

---

## 🎨 Visual: V3 vs V4 Architecture

### Uniswap V3 Architecture
```
