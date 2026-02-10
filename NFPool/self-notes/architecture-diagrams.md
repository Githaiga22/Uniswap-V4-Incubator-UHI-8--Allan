# NFPool Architecture Diagrams

Detailed visual representations of NFPool architecture and flows.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NFPool Framework                         │
│                                                              │
│  ┌──────────────┐                    ┌──────────────┐      │
│  │              │                    │              │      │
│  │  Mode A:     │                    │  Mode B:     │      │
│  │  Collateral  │                    │  Speculative │      │
│  │              │                    │              │      │
│  │  NFT → Token │                    │  Token → NFT │      │
│  │  (Backed)    │                    │  (Buy/Burn)  │      │
│  │              │                    │              │      │
│  └──────┬───────┘                    └──────┬───────┘      │
│         │                                   │              │
│         └───────────────┬───────────────────┘              │
│                         │                                  │
│                         ▼                                  │
│              ┌─────────────────────┐                       │
│              │   NFPool Hook       │                       │
│              │   (Policy Engine)   │                       │
│              └─────────┬───────────┘                       │
│                        │                                   │
│         ┌──────────────┼──────────────┐                    │
│         │              │              │                    │
│         ▼              ▼              ▼                    │
│   ┌─────────┐    ┌─────────┐   ┌──────────┐              │
│   │   NFT   │    │ Strategy│   │ Uniswap  │              │
│   │  Vault  │    │  Module │   │   Pool   │              │
│   └─────────┘    └─────────┘   └──────────┘              │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## Collateralized Mode Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  COLLATERALIZED MODE                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User                                                       │
│   │                                                         │
│   │ [1] Deposit BAYC #1234                                 │
│   ▼                                                         │
│  ┌──────────┐                                              │
│  │   NFT    │ ←─── Hook enforces backing ratio            │
│  │  Vault   │                                              │
│  └────┬─────┘                                              │
│       │                                                     │
│       │ [2] Mint 1.0 NFT-BAYC tokens                       │
│       ▼                                                     │
│  ┌──────────────────┐                                      │
│  │  Uniswap v4 Pool │ ←─── Trade normally                 │
│  │  BAYC ↔ USDC     │                                      │
│  └──────────────────┘                                      │
│       │                                                     │
│       │ [3] Burn tokens                                    │
│       ▼                                                     │
│  Redeem NFT #1234 (or equivalent)                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Speculative Mode Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   SPECULATIVE MODE                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [1] Token launched (no NFTs required)                      │
│       │                                                     │
│       ▼                                                     │
│  ┌──────────────────┐                                      │
│  │  Uniswap v4 Pool │                                      │
│  │  TOKEN ↔ USDC    │ ←─── Normal trading                 │
│  └────────┬─────────┘                                      │
│           │                                                 │
│           │ [2] Trading fees accumulate                    │
│           ▼                                                 │
│  ┌─────────────────┐                                       │
│  │ Strategy Module │                                       │
│  │ (Hook-triggered)│                                       │
│  └────────┬────────┘                                       │
│           │                                                 │
│           │ [3] Buy NFT from collection                    │
│           ▼                                                 │
│  ┌────────────────┐                                        │
│  │ NFT Marketplace│ (OpenSea, Blur, etc.)                 │
│  └────────┬───────┘                                        │
│           │                                                 │
│           │ [4] Relist at 1.2x                             │
│           ▼                                                 │
│  ┌────────────────┐                                        │
│  │ NFT for Sale   │ (Wait for buyer)                      │
│  └────────┬───────┘                                        │
│           │                                                 │
│           │ [5] NFT sells                                  │
│           ▼                                                 │
│  ┌────────────────┐                                        │
│  │ Use ETH to buy │ ←─── Deflationary pressure            │
│  │ & burn tokens  │                                        │
│  └────────────────┘                                        │
│                                                             │
│  Cycle repeats perpetually                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Hybrid Mode Evolution

```
┌─────────────────────────────────────────────────────────────┐
│                       HYBRID MODE                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Start: Collateralized (Mode A)                            │
│    │                                                        │
│    │ [1] NFT holders deposit → mint backed tokens          │
│    ▼                                                        │
│  Pool has 100% backing                                     │
│    │                                                        │
│    │ [2] Fees accumulate from trading                      │
│    ▼                                                        │
│  Strategy buys MORE NFTs (Mode B behavior)                 │
│    │                                                        │
│    │ [3] Backing ratio increases > 100%                    │
│    ▼                                                        │
│  Over-collateralized pool (125%+)                          │
│    │                                                        │
│    │ [4] Can relist premium NFTs at profit                 │
│    ▼                                                        │
│  Revenue used to buy/burn tokens (Mode B behavior)         │
│                                                             │
│  Result: Collateralized stability + Speculative upside     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Mode Comparison Matrix

| Feature | Collateralized | Speculative | Hybrid |
|---------|---------------|-------------|--------|
| Model | NFT → Token | Token → NFT | Both |
| Backing | 100%+ NFT-backed | Not backed initially | 100%+ with growth |
| Deposits | Users deposit NFTs | No deposits needed | NFT deposits + strategy |
| Redemption | Burn tokens → Get NFT | No redemption rights | Burn tokens → Get NFT |
| Use Case | Liquidity for holders | Speculative exposure | Best of both worlds |
| Risk | Low (always backed) | High (depends on sentiment) | Medium (backed + growth) |
| Launch | Requires NFT deposits | Can launch with 0 NFTs | Requires NFT deposits |

---

## Hook Execution Flow

```
┌────────────────────────────────────────────────────────────┐
│                    Hook Lifecycle                          │
│                                                            │
│  1. User initiates swap                                   │
│     └─> Router.swap()                                     │
│                                                            │
│  2. PoolManager unlocks                                   │
│     └─> PoolManager.unlock()                              │
│                                                            │
│  3. beforeSwap hook called                                │
│     ├─> Verify backing ratio (if collateralized)          │
│     ├─> Calculate dynamic fee                             │
│     ├─> Validate mint caps                                │
│     └─> Return (selector, delta, fee)                     │
│                                                            │
│  4. AMM swap executes                                     │
│     └─> Standard Uniswap v4 swap math                     │
│                                                            │
│  5. afterSwap hook called                                 │
│     ├─> Capture trading fees                              │
│     ├─> Trigger strategy (gas-limited)                    │
│     ├─> Update vault inventory                            │
│     └─> Return (selector, hookDelta)                      │
│                                                            │
│  6. Settlement                                            │
│     └─> Net deltas settled in single transaction          │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## Component Interaction Map

```
                    ┌─────────────┐
                    │    User     │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Router    │
                    └──────┬──────┘
                           │
                           ▼
                ┌────────────────────┐
                │   PoolManager      │
                │  (Singleton Core)  │
                └─────────┬──────────┘
                          │
             ┌────────────┼────────────┐
             │            │            │
             ▼            ▼            ▼
      ┌──────────┐  ┌──────────┐  ┌──────────┐
      │ NFPool   │  │   AMM    │  │  Other   │
      │  Hook    │  │  Logic   │  │  Pools   │
      └────┬─────┘  └──────────┘  └──────────┘
           │
    ┌──────┼──────┐
    │      │      │
    ▼      ▼      ▼
┌───────┐ ┌────┐ ┌────────┐
│ Vault │ │Strat│ │Oracle  │
└───────┘ └────┘ └────────┘
```

---

## State Transition Diagram

```
                    ┌─────────────────┐
                    │   Pool Launch   │
                    └────────┬─────────┘
                             │
                 ┌───────────┴────────────┐
                 │                        │
                 ▼                        ▼
        ┌─────────────────┐     ┌─────────────────┐
        │ Collateralized  │     │  Speculative    │
        │      Mode       │     │      Mode       │
        └────────┬────────┘     └────────┬────────┘
                 │                       │
                 │  Governance           │
                 │  + Health             │
                 │    Check              │
                 │                       │
                 └───────────┬───────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Hybrid Mode    │
                    └─────────────────┘
```
