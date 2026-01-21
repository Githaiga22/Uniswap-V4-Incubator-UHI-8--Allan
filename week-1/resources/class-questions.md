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

### 5. ERC-6909 Claims
**Q**: "For the ERC-6909 claim tokens - are these meant mainly for high-frequency traders, or would regular users also benefit from using them? I'm trying to understand when I'd want to keep tokens in the PoolManager versus just withdrawing them."

**Why this is good**: Shows you want to understand practical applications.

---

### 6. Transient Storage
**Q**: "Since transient storage gets erased after each transaction, what happens if a transaction fails halfway through? Does the cleanup happen automatically, or do we need to handle that?"

**Why this is good**: Shows you're thinking about error handling.

---

## 🤔 Conceptual Understanding Questions

### 7. V3 vs V4 Evolution
**Q**: "What was the main bottleneck or pain point from V3 that V4 was specifically designed to solve? Was it purely gas costs, or were there other major issues?"

**Why this is good**: Shows you want to understand the "why" behind design decisions.

---

### 8. Hook Composability
**Q**: "Can multiple hooks work together on the same pool? For example, could one hook handle dynamic fees while another handles MEV protection? Or is it one hook per pool?"

**Why this is good**: Shows you're thinking about advanced use cases.

---

### 9. Liquidity Fragmentation
**Q**: "With potentially many pools for the same token pair (different hooks, fees, etc.), how do routers decide which pool to use for a swap? Is there a recommended default pool concept?"

**Why this is good**: Shows you understand the tradeoff mentioned in the lesson.

---

## 💰 Economic & Market Questions

### 10. Hook Economics
**Q**: "Who pays for the extra gas cost if a hook adds expensive operations? The trader or the LP? And can hook creators charge fees for using their hooks?"

**Why this is good**: Shows you're thinking about incentives and business models.

---

### 11. Dynamic Fees
**Q**: "For hooks that implement dynamic fees, how quickly can fees adjust? Can they change mid-swap, or are they locked in when the swap starts?"

**Why this is good**: Shows you're thinking about edge cases and atomicity.

---

### 12. MEV Protection
**Q**: "You mentioned MEV protection as a hook use case. Can you give a concrete example of how a hook would protect against something like a sandwich attack?"

**Why this is good**: Shows you want practical examples of abstract concepts.

---

## 🔐 Security Questions

### 13. Hook Security
**Q**: "When someone deploys a pool with a custom hook, how can LPs or traders verify that the hook is safe? Is there a standard auditing process, or do people need to trust the hook creator?"

**Why this is good**: Shows you're thinking about trust and security.

---

### 14. Reentrancy
**Q**: "The locking mechanism prevents issues when operations are happening, but can hooks create reentrancy vulnerabilities? Or does the lock protect against that?"

**Why this is good**: Shows you understand a classic smart contract vulnerability.
