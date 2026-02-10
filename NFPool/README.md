# NFPool: Native NFT Liquidity via Uniswap v4 Hooks

> **Turning NFTs into first-class DeFi primitives through programmable AMM logic**

[![Uniswap v4](https://img.shields.io/badge/Uniswap-v4-FF007A)](https://uniswap.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## TL;DR

NFPool enables **NFT-backed liquidity** by embedding NFT-aware logic directly into Uniswap v4 pools via hooks. No external vaults, no fragmented infrastructure, no custom AMMs — just native, composable NFT liquidity at the protocol layer.

**Key Innovation:** Hooks turn Uniswap v4 into a programmable liquidity engine where NFT collateral, solvency checks, and automated strategies are enforced **inside the swap lifecycle itself**.

---

## The Problem

NFT liquidity is broken:

1. **Illiquidity Crisis**
   - 95% of NFT volume is in top 10 collections
   - Average NFT takes 30+ days to sell
   - Floor fragmentation makes pricing impossible

2. **Fragmented Infrastructure**
   - External vaults (counterparty risk)
   - Custom AMMs (liquidity fragmentation)
   - Off-chain coordination (trust assumptions)
   - Wrapper protocols (complexity tax)

3. **Poor DeFi Composability**
   - NFTs can't be collateral in standard protocols
   - No native integration with AMMs
   - Expensive to bridge NFT liquidity to DeFi

**Result:** $10B+ in NFT value locked out of DeFi.

---

## The Solution

NFPool leverages Uniswap v4 hooks to enforce **NFT-specific rules at the pool level**, eliminating the need for external infrastructure while maintaining full composability.

### What Makes NFPool Different

| Feature | Traditional NFT Protocols | NFPool |
|---------|--------------------------|---------|
| **Architecture** | External vaults + Custom AMMs | Native Uniswap v4 hooks |
| **Backing** | Trust-based or off-chain | On-chain, provable via hooks |
| **Composability** | Limited (wrapped assets) | Native (standard ERC-20 pools) |
| **Liquidity** | Fragmented across venues | Unified Uniswap liquidity |
| **Risk Surface** | High (multiple contracts) | Minimal (hook logic only) |
| **Gas Efficiency** | High (multiple calls) | Optimized (single unlock) |

---

## How It Works

```
User → Router → PoolManager → NFPool Hook → Execution
                                    ↓
                            [NFT Vault + Strategy]
```

### 1. Deposit & Mint (Collateralized)
```
User deposits BAYC #1234 → Vault custody → Mint 1.0 NFT-BAYC tokens
```
- NFT is locked in vault (controlled by hook)
- Tokens are minted 1:1 or fractionally (configurable)
- Backing ratio enforced by hook (e.g., 125% over-collateralized)

### 2. Trade on Uniswap (Native Liquidity)
```
Trader: USDC ↔ NFT-BAYC tokens (standard Uniswap pool)
```
- Trades execute normally through Uniswap AMM
- Hook intercepts `beforeSwap` to check solvency
- Hook intercepts `afterSwap` to route fees and trigger strategies

### 3. Redeem or Hold (Flexible Exit)
```
Burn 1.0 NFT-BAYC tokens → Withdraw BAYC #1234 (or equivalent)
```
- Proportional redemption from vault
- Strategy can auto-rebalance inventory
- Fees accumulate for NFT buybacks

---

## Technical Architecture

### Core Components

#### 1. NFPool Hook (Policy Engine)
The hook is the **enforcement layer** that makes NFT-backed pools trustless:

```solidity
contract NFPoolHook is BaseHook {
    // beforeSwap: Enforce invariants
    function beforeSwap(...) external override {
        // ✓ Check backing ratio (no undercollateralized mints)
        // ✓ Apply dynamic fees (based on inventory/volatility)
        // ✓ Validate mint caps (prevent supply inflation)
    }

    // afterSwap: Route fees and trigger strategies
    function afterSwap(...) external override {
        // → Route fees to vault (for NFT purchases)
        // → Update inventory accounting
        // → Trigger bounded strategy execution
    }

    // unlockCallback: Safe NFT transfers
    function unlockCallback(...) external {
        // → Transfer NFTs during unlock window
        // → Maintain reentrancy safety
    }
}
```

**Hook Capabilities:**
- ✅ Enforces NFT-backed invariants (no unbacked minting)
- ✅ Dynamic fees based on pool health
- ✅ Automated NFT buybacks from trading fees
- ✅ Inventory rebalancing (buy floor, sell premium)
- ✅ Solvency checks (prevent bank runs)

#### 2. NFT Vault (Custody Layer)
```solidity
struct NFTVault {
    mapping(uint256 => address) tokenOwner;  // NFT custody
    uint256 backingRatio;                    // e.g., 125% = over-collateralized
    uint256[] inventory;                     // Held NFT IDs
    uint256 floorPrice;                      // Oracle or TWAP
}
```

**Security Properties:**
- Hook-only access (no direct user withdrawals)
- Transfers only during `unlockCallback` (reentrancy-safe)
- Auditable backing via on-chain verification

#### 3. Strategy Module (Optional, Non-Blocking)
```solidity
struct StrategyConfig {
    bool enabled;
    uint256 feeThreshold;      // Min fees before execution
    uint256 maxGasPerSwap;     // Gas budget (won't block swaps)
    address[] marketplaces;    // Whitelisted NFT venues
}
```

**Strategy Actions:**
- Buy NFTs when fees accumulate (strengthen backing)
- Relist at premium (generate revenue for LPs)
- Rebalance inventory (maintain floor exposure)
- Burn tokens on NFT sales (deflationary pressure)

**Critical Property:** If strategy fails or is disabled, the pool remains fully functional.

---

## Use Cases

### 1. NFT Holder Liquidity
**Problem:** You own a $50k BAYC but need $10k liquidity today.

**NFPool Solution:**
```
Deposit BAYC → Mint 1.0 NFT-BAYC → Swap 20% to USDC → Keep 80% exposure
```
- No forced sale at floor price
- Maintain upside exposure
- Instant liquidity without marketplace listing

### 2. Fractional Trading
**Problem:** You want exposure to expensive NFTs but can't afford whole units.

**NFPool Solution:**
```
Buy 0.01 NFT-BAYC tokens for ~$500 → Trade like any ERC-20
```
- Trade fractional NFT exposure on Uniswap
- Exit to USDC or redeem proportional NFT value
- No custom marketplace needed

### 3. DAO Treasury Management
**Problem:** DAOs hold NFTs but can't easily provide liquidity or earn yield.

**NFPool Solution:**
```
DAO deposits treasury NFTs → Launch NFPool with strategy → Earn fees + grow NFT holdings
```
- Trading fees buy more NFTs from collection
- Automated floor sweeping during bear markets
- Transparent on-chain accounting

### 4. Gaming & Social NFTs
**Problem:** In-game NFTs are illiquid and trapped in walled gardens.

**NFPool Solution:**
```
Game integrates NFPool SDK → Players trade in-game items on Uniswap → Composable with DeFi
```
- Native liquidity for game assets
- Cross-game NFT liquidity
- Instant arbitrage between in-game and external markets

### 5. Speculative NFT Exposure (vs NFTStrategy)
**How NFPool differs from projects like PunkStrategy:**

| Feature | NFTStrategy/PunkStrategy | NFPool |
|---------|-------------------------|---------|
| **Model** | Token → Buy NFTs → Relist → Burn | NFT → Collateralize → Trade → Redeem |
| **Backing** | None (speculative) | Direct NFT backing |
| **Use Case** | Speculative exposure (like an ETF) | Liquidity provision (like a CDP) |
| **Integration** | External marketplace logic | Native Uniswap v4 hooks |
| **Risk** | Token can go to 0 without backing | Token always backed by NFT value |

**They're complementary:**
- NFTStrategy = "Buy and burn" model for speculation
- NFPool = Collateralized liquidity for NFT holders

---

## Technical Innovations

### 1. Hook-Native Backing Verification
```solidity
// Traditional: External vault with trust assumptions
// NFPool: Hook enforces backing on every swap
if (vault.inventory.value() < totalSupply * backingRatio) {
    revert InsufficientBacking();
}
```

### 2. Dynamic Fee Model
```solidity
// Fees adjust based on pool health
uint24 dynamicFee = baseFee + (
    inventory < targetInventory
        ? premiumFee  // Incentivize NFT deposits
        : discountFee // Encourage trading
);
```

### 3. Bounded Strategy Execution
```solidity
// Strategy has gas budget, won't DoS swaps
uint256 gasLimit = 50_000; // Max 50k gas per swap
(bool success,) = strategy.call{gas: gasLimit}(data);
// If fails, swap still succeeds
```

### 4. Inventory Rebalancing
```solidity
// Automatically manage floor vs premium NFTs
if (nft.price < floorPrice * 0.95) {
    buyNFT(nft); // Buy undervalued NFTs
} else if (nft.price > floorPrice * 1.2) {
    listNFT(nft, floorPrice * 1.15); // Relist at premium
}
```

---

## Developer Experience

### SDK (Abstraction Layer)

Developers don't need to understand hooks to use NFPool:

```typescript
import { NFPool } from '@nfpool/sdk';

// Deploy NFT-backed pool in 5 lines
const pool = await NFPool.create({
  chain: 'base',
  nftCollection: '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D', // BAYC
  backingRatio: 1.25, // 125% over-collateralized
  feeModel: 'dynamic',
  strategy: {
    enabled: true,
    buyNFTsOnSurplus: true,
    relistMultiplier: 1.2,
    maxGasPerSwap: 50_000
  }
});

await pool.deploy();
// Done! Pool is live with NFT-backed tokens

// Analytics
const backing = await pool.analytics.backingRatio(); // e.g., 1.32x
const inventory = await pool.analytics.inventory();  // [#1234, #5678, ...]
const fees = await pool.analytics.feeFlow();         // 2.5 ETH this week
```

### What the SDK Handles
- ✅ Hook deployment and registration
- ✅ Vault deployment and initialization
- ✅ Pool creation on Uniswap v4
- ✅ Router authorization
- ✅ Safety defaults (gas limits, backing checks)
- ✅ Analytics and monitoring

### Frontend Integration
```typescript
// User deposits NFT
await nfpool.deposit({
  nftId: 1234,
  onMint: (tokens) => console.log(`Minted ${tokens} NFT-BAYC`)
});

// User swaps tokens
await nfpool.swap({
  from: 'NFT-BAYC',
  to: 'USDC',
  amount: 0.5 // Swap 50% of position
});

// User redeems NFT
await nfpool.redeem({
  amount: 1.0, // Burn 1 token
  preferredNFT: 1234 // Optional: get specific NFT back
});
```

---

## Security Model

### Threat Model

| Threat | Mitigation |
|--------|-----------|
| **Unbacked minting** | Hook enforces backing ratio on every swap |
| **Reentrancy** | NFT transfers only during `unlockCallback` |
| **Griefing attacks** | Strategy has gas budget, won't DoS swaps |
| **Oracle manipulation** | Use TWAP + conservative floor estimates |
| **Vault drainage** | Hook-only access, timelocked governance |

### Assumptions
- ✅ Uniswap v4 core is trusted (audited)
- ✅ Only authorized routers can initiate swaps
- ✅ NFT price feeds provide conservative estimates
- ✅ Governance is timelocked (48h minimum)

### Audit Checklist
- [ ] Hook access controls
- [ ] Vault custody logic
- [ ] Strategy gas limits
- [ ] Oracle price validation
- [ ] Emergency pause mechanisms

---

## Roadmap

### Phase 1: Foundation (Hackathon)
- [x] Core hook architecture
- [x] Basic vault implementation
- [ ] Simple strategy (fee-based buybacks)
- [ ] SDK v1 (create, deploy, analytics)
- [ ] Testnet deployment (Base Sepolia)

### Phase 2: Launch
- [ ] Audit by Code4rena/Sherlock
- [ ] Mainnet deployment (Base)
- [ ] Launch with top 3 NFT collections (BAYC, Punks, Pudgy)
- [ ] Frontend v1 (deposit, swap, redeem)
- [ ] Analytics dashboard

### Phase 3: Scale
- [ ] Multi-collection pools (basket exposure)
- [ ] Cross-chain expansion (Arbitrum, Optimism)
- [ ] Advanced strategies (MEV protection, arbitrage)
- [ ] DAO governance for parameters
- [ ] Integration with lending protocols

### Phase 4: Ecosystem
- [ ] Gaming partnerships (in-game NFT liquidity)
- [ ] Wallet integrations (1-click NFT → liquidity)
- [ ] API for NFT marketplaces (instant liquidity quotes)
- [ ] White-label SDK for projects

---

## Why NFPool Wins

### Technical Excellence
- **Hook-native design:** Showcases Uniswap v4's unique capabilities
- **Novel architecture:** First NFT-backed liquidity via hooks
- **Gas optimization:** Single unlock for NFT transfers

### Real-World Impact
- **$10B+ addressable market:** NFT holders need liquidity
- **Composability unlock:** NFTs become DeFi primitives
- **Infrastructure play:** SDK enables ecosystem growth

### Team Execution
- **Clean implementation:** Well-documented, auditable code
- **Developer-first:** SDK abstracts complexity
- **Scalable design:** Works for gaming, art, social NFTs

---

## Comparison to Existing Solutions

### vs Sudoswap / NFTx
- **Their approach:** Custom AMM bonding curves
- **NFPool advantage:** Uses Uniswap liquidity, no fragmentation

### vs Blur / OpenSea
- **Their approach:** Marketplace with order books
- **NFPool advantage:** Instant liquidity via AMM, no waiting

### vs NFTStrategy / PunkStrategy
- **Their approach:** Buy and burn tokens (speculative)
- **NFPool advantage:** Direct NFT backing (collateralized)

### vs Fractional.art
- **Their approach:** External vault + governance
- **NFPool advantage:** Trustless via hooks, no governance attacks

---

## Getting Started

### For Developers
```bash
npm install @nfpool/sdk
```

See [SDK Documentation](./docs/SDK.md) for full API reference.

### For Users
Visit [nfpool.xyz](https://nfpool.xyz) (coming soon) to:
- Deposit NFTs for instant liquidity
- Trade fractional NFT exposure
- Monitor pool backing and fees

### For Researchers
Read the [Technical Whitepaper](./docs/WHITEPAPER.md) for:
- Formal verification of invariants
- Economic modeling of fee structures
- Security analysis

---

## Contributing

NFPool is open-source and welcomes contributions:

- **Code:** Submit PRs for hook logic, SDK features, or frontend
- **Security:** Report vulnerabilities via [security@nfpool.xyz]
- **Docs:** Improve README, tutorials, or SDK documentation
- **Ideas:** Open issues for feature requests or design discussions

---

## References

- [Uniswap v4 Hooks Documentation](https://docs.uniswap.org/contracts/v4/overview)
- [EIP-1153: Transient Storage](https://eips.ethereum.org/EIPS/eip-1153)
- [NFT Liquidity Research (Paradigm)](https://www.paradigm.xyz/2021/10/nft-liquidity)
- [PunkStrategy Model](https://twitter.com/token_works) (for comparison)

---

## License

MIT License - see [LICENSE](./LICENSE) for details.

---

## Contact

- Twitter: [@nfpool](https://twitter.com/nfpool)
- Discord: [discord.gg/nfpool](https://discord.gg/nfpool)
- Email: team@nfpool.xyz

---

**Built with Uniswap v4 hooks. Made for the hookathon. Designed for the future of NFT liquidity.**
