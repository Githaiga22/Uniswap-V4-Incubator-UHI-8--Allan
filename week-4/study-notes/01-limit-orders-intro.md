# Liquidity Operator: Limit Order Hook - Introduction

**Author**: Allan Robinson
**Date**: February 2026
**Topic**: Limit Orders and Take-Profit Orders on Uniswap v4

---

## Lesson Objectives

- Learn what limit orders are - and specifically what take-profit orders are
- Understand the mechanism design of how we can implement an order book through a hook
- Partially build out the hook (with the rest in Part 2)

---

## Introduction

In this lesson, we're looking at limit orders - and creating an onchain order book directly integrated into Uniswap through a hook.

This is the first foray in this course where we start looking at ideas that have the potential to actually be big onchain businesses. While the hook we cover itself will not be fully production-ready - to respect the time and duration of this course - it will lay the foundation on which further improvements can be done to make something like this a reality.

Today, specifically, we're starting work on a hook that is capable of executing "take-profit orders".

---

## What is a Take-Profit Order?

A take-profit is a type of order where the user wants to sell a token once its price increases to a certain amount.

**Example**:
- ETH is currently trading at 3,500 USDC
- I can place a take-profit order: "Sell 1 ETH when it's trading at 4,000 USDC"

This will be a fairly long hook - more than we could cover in a single 90-minute workshop - so it's broken up into two parts:

### Part 1 Focus
- Functionality for creating and canceling orders
- Writing the code to fulfill an order
- Related tests

### Part 2 Focus
- Writing the actual hook function (afterSwap)
- Combining all the ideas
- End-to-end tests

---

## Mechanism Design

At a very high level - a few things we will need:

1. **Ability to place an order**
2. **Ability to cancel an order** after placing (if not filled yet)
3. **Ability to withdraw/redeem tokens** after order is filled

All of these are things that don't really have anything to do with Uniswap - they will be public functions directly on the hook that users can call.

---

## How Do We Execute Orders?

Let's think about when and how orders get executed.

### Tick Movement and Order Execution

Assume a pool of two tokens A and B:
- A is Token 0
- B is Token 1
- Current tick: 600 (A is more expensive than B)

Two types of take-profit orders are possible:

**Case 1: Sell Token A when price increases**
- Price increase of A = tick increasing (since A is Token 0)

**Case 2: Sell Token B when price increases**
- Price increase of B = tick decreasing (since B is Token 1)

### When Do Ticks Change?

**Ticks change when swaps happen.**

---

## Execution Flow

1. Alice places an order on the hook to sell Token A for Token B at a tick greater than current tick
2. Bob comes around and does a normal swap to buy Token A and sell Token B
3. Bob's swap makes the price of Token A go up
4. **afterSwap** we check if the tick changed enough to execute Alice's order
5. If yes, hook conducts another swap - fulfilling Alice's order
6. Therefore, Bob's transaction got his swap done AND Alice's order got filled

### Why afterSwap?

We use **afterSwap** for executing orders since executing the order will further move the tick in some direction.

- Doing it in **beforeSwap** would affect the swap Bob wanted to execute - we don't want that
- We want Bob's trade to go through normally
- Execute pending orders AFTER his trade is done

---

## Handling Multiple Users with Same Order

Multiple people can potentially place the exact same order:
- Two people can choose to sell the same token
- At the same tick
- In the same pool

**Solution: ERC-1155 Claim Tokens**

We will have our hook be an **ERC-1155 contract** to:
- Issue "claim" tokens to users proportional to their input tokens
- Use these to calculate how many output tokens are claimable
- Support proportional redemption

---

## Assumptions (For Simplicity)

To keep things relatively simple, we make some assumptions:

1. **No gas limit considerations**: We try to fulfill every order within the tick range with zero consideration for gas costs. In production, there should be limits to keep costs reasonable.

2. **No slippage protection**: We allow infinite slippage. In practice, makers should be able to set slippage limits.

3. **No native ETH support**: We will not support pools with native ETH. No technical reason - just keeps code shorter for educational purposes.

---

## Key Takeaways

- Limit orders execute when price crosses a specific tick
- We use **afterSwap** to detect tick crossings and execute orders
- **ERC-1155 tokens** represent claim rights to output tokens
- Multiple users can place the same order parameters
- The hook acts as an on-chain order book integrated with Uniswap

---

## Next Steps

In the next lesson, we'll:
1. Set up the Foundry project
2. Create the hook contract structure
3. Implement order placement functionality
4. Implement order cancellation
5. Set up basic tests
