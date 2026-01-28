# MyFirstHook Implementation Notes

**Author**: Allan Robinson
**Date**: January 27, 2026
**Context**: Week 2 - Building My First Hook with Tom Wade

---

## Concept

MyFirstHook is a simple swap counter that tracks how many swaps occur in each pool. It demonstrates the core hook pattern without unnecessary complexity.

---

## Architecture

```
Pool Lifecycle Event Flow:
┌─────────────┐
│  User calls │
│  swap()     │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│  beforeSwap()   │ ← Hook intercepts
│  (count++)      │
└──────┬──────────┘
       │
       ▼
