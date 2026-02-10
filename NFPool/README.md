# NFPool: Native NFT Liquidity Infrastructure

> Programmable NFT liquidity powered by Uniswap v4 hooks

[![Uniswap v4](https://img.shields.io/badge/Uniswap-v4-FF007A)](https://uniswap.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Overview

NFPool is a programmable liquidity framework built on Uniswap v4 that transforms NFTs into liquid, composable financial instruments. By embedding NFT-aware logic directly into AMM pools via hooks, NFPool eliminates the need for external vaults, fragmented infrastructure, or trust assumptions.

**Core Innovation:** Hooks enforce NFT collateralization, dynamic pricing, and automated strategies at the protocol level—making NFT liquidity native to Uniswap v4 rather than bolted on through external systems.

---

## The NFT Liquidity Problem

NFT markets suffer from fundamental liquidity constraints:

**Illiquidity Crisis**
- 95% of NFT trading volume concentrated in top 10 collections
- Average time to sell: 30+ days
- Floor price fragmentation makes pricing impossible
- $10B+ in NFT value locked out of DeFi

**Fragmented Infrastructure**
- External custody systems introduce counterparty risk
- Custom AMM implementations fragment liquidity
- Off-chain coordination creates trust assumptions
- Wrapper protocols add unnecessary complexity

**Poor DeFi Integration**
- NFTs cannot serve as collateral in standard protocols
- No native AMM support for NFT-backed tokens
- High friction bridging NFT value to DeFi primitives

---

## Solution Architecture

NFPool leverages Uniswap v4's hook system to implement NFT-specific logic at the pool level. This architectural approach provides:

### Unified Liquidity Framework

NFPool implements a dual-mode system within a single framework, allowing pools to operate in different configurations based on use case requirements:

**Collateralized Mode**
- NFTs deposited into vault custody
- Tokens minted with provable backing ratio
- Redemption rights enforced by hooks
- Over-collateralization prevents bank runs

**Speculative Mode**
- Trading fees accumulate in strategy module
- Automated NFT purchases from marketplace
- Revenue generation through strategic relisting
- Token burn mechanism creates deflationary pressure

**Hybrid Mode**
- Combines collateralized safety with speculative growth
- Fees strengthen backing ratio above minimum threshold
- Premium NFT sales generate revenue
- Pools can transition between modes based on governance

### Key Benefits

**Protocol-Level Security**
- Hook enforcement eliminates trust assumptions
- On-chain verification of backing ratios
- Reentrancy-safe NFT transfers via unlockCallback
- Non-blocking strategies prevent DOS attacks

**Capital Efficiency**
- Single unlock window for all operations
- Gas-optimized hook execution
- No duplicate storage across external contracts
- Unified liquidity pool for all participants

**Composability**
- Standard ERC-20 tokens backed by NFTs
- Native Uniswap liquidity integration
- Compatible with existing DeFi protocols
- Programmatic pool creation and management

**Flexibility**
- Custom pool configurations per collection
- Dynamic fee structures based on pool health
- Automated strategy execution with gas limits
- Mode transitions via governance

---

## Technical Architecture

### Core Components

**NFPool Hook**

The hook serves as the policy enforcement engine for the pool:

```
┌─────────────────────────────────────────────────────┐
│                   NFPool Hook                       │
│                                                     │
│  beforeSwap()                                       │
│  ├─ Verify backing ratio (collateralized mode)     │
│  ├─ Apply dynamic fee based on pool health         │
│  ├─ Validate mint caps                             │
│  └─ Return custom pricing if applicable            │
│                                                     │
│  afterSwap()                                        │
│  ├─ Capture trading fees                           │
│  ├─ Trigger strategy execution (gas-limited)       │
│  ├─ Update vault inventory                         │
│  └─ Emit accounting events                         │
│                                                     │
│  unlockCallback()                                   │
│  ├─ Execute NFT transfers atomically               │
│  └─ Maintain reentrancy safety                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**NFT Vault**

Custody layer for collateralized pools:
- Holds deposited NFTs with owner tracking
- Calculates total backing value via oracle integration
- Enforces redemption logic based on token burns
- Maintains inventory for strategy operations

**Strategy Module**

Optional execution layer for automated operations:
- Purchases NFTs when fee threshold reached
- Relists acquired NFTs at target markup
- Burns tokens using sale proceeds
- Gas-limited execution prevents transaction failures

### Hook Integration Flow

```
User → Router → PoolManager → NFPool Hook
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
              NFT Vault       Strategy        Uniswap Pool
                                Module
```

All operations occur within a single unlock window, minimizing gas costs and ensuring atomic execution.

---

## Technical Innovations

### Hook-Native Backing Verification

Traditional NFT liquidity solutions rely on external contracts to verify collateralization, introducing trust assumptions and potential attack vectors. NFPool enforces backing ratios directly in the hook's beforeSwap function, making undercollateralized states impossible at the protocol level.

### Dynamic Fee Structures

Fee rates adjust automatically based on pool health metrics:
- Low inventory relative to supply triggers premium fees to incentivize deposits
- High inventory enables discounted fees to encourage trading activity
- Real-time calculation prevents manipulation through front-running

### Bounded Strategy Execution

Strategy operations have strict gas budgets (50,000 gas) to prevent denial-of-service attacks. If strategy execution fails or exceeds gas limits, the swap completes successfully and fees accumulate for future attempts.

### Mode Transitions

Pools can evolve their operational mode through governance:
- Collateralized pools can activate speculative features once backing exceeds safety thresholds
- Speculative pools can transition to collateralized once sufficient NFT inventory is acquired
- Hybrid pools can adjust the balance between stability and growth based on market conditions

---

## Use Cases

### NFT Holder Liquidity

Holders of valuable NFTs can access liquidity without forced sales:
- Deposit NFT to mint backed tokens
- Swap portion of tokens for immediate liquidity
- Maintain exposure to remaining token balance
- Redeem NFT by burning full token amount

### Fractional NFT Access

High-value NFT collections become accessible to retail participants:
- Purchase fractional token amounts on Uniswap
- Trade fractional positions with standard AMM liquidity
- Exit to stablecoin or redeem proportional NFT value
- No minimum position size requirements

### DAO Treasury Management

DAOs holding NFT assets can optimize capital efficiency:
- Provide liquidity while maintaining NFT exposure
- Earn trading fees on treasury assets
- Automated floor sweeping during favorable market conditions
- Transparent on-chain accounting for all operations

### Gaming Asset Liquidity

In-game NFTs gain liquidity through native integration:
- Players deposit game assets to access instant liquidity
- Cross-game trading through unified Uniswap pools
- Arbitrage opportunities between in-game and external markets
- Composability with DeFi lending protocols

### Collection Exposure

Traders can gain exposure to NFT collections without custody:
- Token-based speculation on collection performance
- Automated accumulation strategy strengthens backing over time
- Revenue generation through strategic NFT trading
- Deflationary mechanics create long-term value accrual

---

## Building on Uniswap v4

NFPool leverages Uniswap v4's architectural innovations:

**Hook System**
- BeforeSwap: Enforce invariants, apply custom pricing
- AfterSwap: Capture fees, trigger strategies
- BeforeSwapReturnDelta: Override AMM pricing when beneficial
- AfterSwapReturnDelta: Extract value without affecting swap math

**Singleton Architecture**
- All pools managed by single PoolManager contract
- Efficient cross-pool operations
- Reduced deployment costs
- Simplified integration layer

**Flash Accounting**
- Operations batched within unlock window
- Net settlement reduces gas costs
- Atomic NFT transfers prevent reentrancy
- Failed strategies don't revert swaps

**Custom Pool Creation**
- Programmable pool parameters per collection
- Dynamic fee structures without external coordination
- Governance-controlled pool evolution
- Permissionless deployment for any NFT collection

---

## Key Differentiators

**Protocol-Native Design**

NFPool implements NFT liquidity as a first-class Uniswap v4 feature rather than an external system. This architectural choice provides:
- Trustless operation through hook enforcement
- Gas efficiency via singleton architecture
- Unified liquidity without fragmentation
- Standard interfaces for ecosystem integration

**Flexible Pool Modes**

Unlike single-purpose solutions, NFPool supports multiple operational modes within one framework:
- Collateralized pools provide safe NFT-backed liquidity
- Speculative pools enable collection exposure without custody
- Hybrid pools combine stability with growth mechanisms
- Governance-driven transitions adapt to market conditions

**Programmable Liquidity**

The hook system enables sophisticated pool behaviors:
- Dynamic fee adjustment based on real-time metrics
- Automated strategy execution with safety limits
- Custom pricing curves for specific use cases
- Composable hooks for advanced functionality

---

## Security Model

**Threat Mitigation**

| Threat Vector | Mitigation Strategy |
|--------------|-------------------|
| Unbacked minting | Hook enforces backing ratio on every swap |
| Reentrancy attacks | NFT transfers only during unlockCallback |
| Strategy DOS | 50k gas limit prevents transaction failures |
| Oracle manipulation | TWAP averaging with conservative floors |
| Vault drainage | Hook-only access with timelocked governance |
| Mode exploits | Health checks required for transitions |

**Security Assumptions**

- Uniswap v4 core contracts are secure (audited by Trail of Bits)
- Only authorized routers can initiate swaps
- Oracle price feeds provide conservative estimates
- Governance decisions have minimum 48-hour timelock

**Mode-Specific Considerations**

Collateralized Mode:
- Bank run risk mitigated through over-collateralization requirements
- Redemption fees dampen rapid withdrawal incentives
- Backing ratio enforced before every mint operation

Speculative Mode:
- Token value depends on strategy execution success
- No guaranteed backing creates higher risk profile
- Strategy accumulation builds collateral over time

Hybrid Mode:
- Complexity requires comprehensive testing
- Clear governance processes for parameter adjustment
- Monitoring systems track mode-specific metrics

---

## Implementation Status

**Completed**
- Core hook architecture with multi-mode support
- NFT vault custody implementation
- Dynamic fee calculation system
- Strategy module with gas limiting

**In Development**
- Oracle integration for price feeds
- Frontend interface for pool interaction
- Analytics dashboard for pool metrics
- Governance system for parameter adjustment

**Planned**
- Multi-collection basket pools
- Cross-chain deployment
- Advanced strategy modules
- Lending protocol integration

---

## Technical Requirements

**Dependencies**
- Uniswap v4 core contracts (v4.0.0+)
- Solidity 0.8.26+
- Foundry development framework
- OpenZeppelin contracts for standards

**Network Support**
- Base (primary deployment target)
- Ethereum mainnet
- Arbitrum, Optimism (future)

**Oracle Support**
- Chainlink price feeds
- Uniswap v3 TWAP
- Custom oracle adapters

---

## License

MIT License - See LICENSE file for details

---

## Documentation

Detailed implementation documentation available in `/self-notes/`:
- Technical specifications
- Code examples
- Integration guides
- Strategy patterns

---

**NFPool: Transforming NFTs into liquid, composable financial primitives through programmable AMM infrastructure.**
