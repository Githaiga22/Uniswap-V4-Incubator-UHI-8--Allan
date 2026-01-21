# Smart Questions to Ask in Class - Week 1

**Date**: January 20, 2026

---

## 🎯 Architecture & Design Questions

### 1. Singleton Design
**Q**: "You mentioned all pools live in one PoolManager contract now. What happens if there's a bug in the PoolManager? Would that affect ALL pools, versus V3 where only one pool would be affected?"

**Why this is good**: Shows you understand the tradeoff between efficiency and risk.

---

### 2. Gas Savings
**Q**: "The gas savings from flash accounting sound amazing for multi-hop swaps. But for simple single swaps, is there actually a significant gas difference compared to V3? Or is the benefit mainly for complex trades?"

**Why this is good**: Shows you're thinking critically about real-world use cases.

---

### 3. Hook Limitations
**Q**: "Since hooks can add arbitrary code, is there a gas limit or complexity limit for what a hook can do? Like, could a hook theoretically make a pool too expensive to use?"

**Why this is good**: Shows you're thinking about practical constraints.

---

## 🔧 Technical Implementation Questions

### 4. Hook Address Bitmap
**Q**: "The hook address bitmap system is clever, but what prevents someone from accidentally deploying a hook at an address that signals functions it doesn't actually implement? Would pools just fail when they try to call those functions?"

**Why this is good**: Shows you understand the system but want to know about edge cases.

---
