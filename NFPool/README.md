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

## How It Works

### Complete User Journey: Collateralized Mode

```
┌─────────────────────────────────────────────────────────────────────┐
│                     COLLATERALIZED MODE USER FLOW                   │
└─────────────────────────────────────────────────────────────────────┘

Step 1: NFT Holder Deposits
────────────────────────────
User owns BAYC #1234
    │
    │ [Calls NFPool SDK]
    ▼
sdk.deposit({ nftId: 1234 })
    │
    ├─> NFT transferred to Vault
    ├─> Hook verifies collection
    ├─> Oracle checks floor price (50 ETH)
    └─> Mint 1.0 NFT-BAYC token to user

Result: User has 1.0 liquid token, NFT locked in vault


Step 2: User Trades on Uniswap
────────────────────────────────
User wants $10k liquidity
    │
    │ [Swaps on Uniswap v4]
    ▼
sdk.swap({ from: 'NFT-BAYC', to: 'USDC', amount: 0.2 })
    │
    ├─> beforeSwap: Hook checks backing ratio ✓
    ├─> AMM swap: 0.2 NFT-BAYC → 10,000 USDC
    ├─> afterSwap: Hook captures 1% fee (100 USDC)
    └─> User receives 9,900 USDC

Result: User has 9,900 USDC + 0.8 NFT-BAYC tokens remaining


Step 3: User Redeems NFT
────────────────────────────────
User wants NFT back
    │
    │ [Calls NFPool SDK]
    ▼
sdk.redeem({ amount: 1.0 })
    │
    ├─> Burns 1.0 NFT-BAYC token
    ├─> Hook verifies ownership
    ├─> Vault selects NFT (BAYC #1234 or equivalent)
    └─> NFT transferred back to user

Result: User has original NFT back, tokens burned
```

### Complete User Journey: Speculative Mode

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SPECULATIVE MODE USER FLOW                      │
└─────────────────────────────────────────────────────────────────────┘

Step 1: Trader Buys Exposure
────────────────────────────────
Trader wants BAYC exposure without buying NFT
    │
    │ [Swaps on Uniswap v4]
    ▼
sdk.swap({ from: 'USDC', to: 'BAYC-SPEC', amount: 1000 })
    │
    ├─> AMM swap: 1,000 USDC → 0.05 BAYC-SPEC tokens
    ├─> afterSwap: Hook captures 1% fee (10 USDC)
    └─> User receives 0.05 BAYC-SPEC tokens

Result: Trader has speculative exposure, no NFT custody


Step 2: Strategy Executes (Automated)
────────────────────────────────────────
Fees accumulate to threshold (0.1 ETH)
    │
    │ [Hook triggers strategy in afterSwap]
    ▼
strategy.buyNFT(feeAmount: 0.1 ETH)
    │
    ├─> Purchase BAYC #5678 from OpenSea
    ├─> Relist BAYC #5678 at 1.2x (0.12 ETH)
    └─> Wait for buyer

Result: Strategy holds NFT, accumulating backing


Step 3: NFT Sells, Tokens Burn
────────────────────────────────
BAYC #5678 sells for 0.12 ETH
    │
    │ [Strategy receives proceeds]
    ▼
strategy.onNFTSold(salePrice: 0.12 ETH)
    │
    ├─> Use 0.12 ETH to buy BAYC-SPEC tokens
    ├─> Burn purchased tokens
    └─> Emit TokensBurned event

Result: Token supply decreases, price pressure increases
```

### SDK Usage Flow (Developer Perspective)

```
┌─────────────────────────────────────────────────────────────────────┐
│                      DEVELOPER: POOL CREATION                       │
└─────────────────────────────────────────────────────────────────────┘

Step 1: Install SDK
──────────────────────
npm install @nfpool/sdk


Step 2: Configure Pool
──────────────────────
import { NFPool } from '@nfpool/sdk';

const pool = await NFPool.create({
  mode: 'HYBRID',              // Choose mode
  nftCollection: '0xBAYC...',  // Target collection
  backingRatio: 1.5,           // 150% over-collateralized
  feeModel: 'dynamic',         // Dynamic fees based on health
  strategy: {
    enabled: true,
    buyNFTsOnSurplus: true,
    relistMultiplier: 1.2
  }
});


Step 3: Deploy to Network
──────────────────────────
await pool.deploy();
// Output: Pool deployed at 0x1234...
//         Hook address: 0x5678...
//         Vault address: 0x9012...


Step 4: Monitor & Manage
──────────────────────────
const stats = await pool.analytics();
console.log(stats.backingRatio);  // 1.52x
console.log(stats.totalNFTs);     // 45
console.log(stats.weeklyVolume);  // 125.3 ETH
```

### Hook Execution Flow (Technical Detail)

```
┌─────────────────────────────────────────────────────────────────────┐
│              SWAP LIFECYCLE: Hook Execution Sequence                │
└─────────────────────────────────────────────────────────────────────┘

User: Swap 1.0 NFT-BAYC → USDC
       │
       ▼
┌──────────────────┐
│  1. User Action  │
└────────┬─────────┘
         │ router.swap(...)
         ▼
┌──────────────────┐
│  2. PoolManager  │  ← Single unlock window starts
└────────┬─────────┘
         │ unlock()
         ▼
┌──────────────────────────────────────────┐
│  3. beforeSwap() Hook                    │
│  ─────────────────────────────────       │
│  ✓ Check backing ratio                   │
│    → vault.totalValue() >= required?     │
│    → ✓ 75 ETH >= 50 ETH (150% target)   │
│                                          │
│  ✓ Calculate dynamic fee                 │
│    → poolHealth = 0.85                   │
│    → fee = baseFee + premium             │
│    → fee = 0.003 (0.3%)                  │
│                                          │
│  ✓ Validate mint cap                     │
│    → totalSupply < maxSupply ✓           │
│                                          │
│  Return: (selector, delta, fee)          │
└────────┬─────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│  4. AMM Swap Executes                    │
│  ─────────────────────────────────       │
│  • Input: 1.0 NFT-BAYC token             │
│  • Output: Calculate based on xy=k       │
│  • With fee: 0.3% to hook               │
│  • User receives: ~50,000 USDC           │
└────────┬─────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│  5. afterSwap() Hook                     │
│  ─────────────────────────────────       │
│  ✓ Capture fee                           │
│    → fee = 50,000 × 0.003 = 150 USDC    │
│    → take(USDC, 150)                     │
│                                          │
│  ✓ Trigger strategy (gas-limited)        │
│    → strategy.buyNFT{gas: 50k}(150)     │
│    → if (success) accumulate backing     │
│    → if (fail) fees accumulate           │
│                                          │
│  ✓ Update vault inventory                │
│    → vault.updateAccounting()            │
│                                          │
│  ✓ Emit events                           │
│    → SwapExecuted(user, amount, fee)     │
│                                          │
│  Return: (selector, hookDelta)           │
└────────┬─────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│  6. Settlement   │  ← Unlock window closes
│  ──────────────  │
│  • Net deltas    │
│  • User receives │
│    49,850 USDC   │
└──────────────────┘
```

### End-to-End: From NFT to Liquidity in 3 Steps

```
╔════════════════════════════════════════════════════════════════╗
║                    USER: Alice (NFT Holder)                    ║
╚════════════════════════════════════════════════════════════════╝

Problem: Alice owns BAYC #1234 (worth ~50 ETH) but needs 10 ETH today
         Doesn't want to sell entire NFT on OpenSea

Solution: NFPool Collateralized Mode

┌─────────────┐
│   START     │  Alice has: BAYC #1234
└──────┬──────┘             0 ETH liquidity
       │
       │ STEP 1: Deposit NFT
       │ ─────────────────────
       │ sdk.deposit({ nftId: 1234 })
       │
       ▼
┌─────────────┐
│  DEPOSITED  │  Alice has: 1.0 NFT-BAYC token
└──────┬──────┘             BAYC #1234 in vault
       │
       │ STEP 2: Swap portion for ETH
       │ ──────────────────────────────
       │ sdk.swap({
       │   from: 'NFT-BAYC',
       │   to: 'ETH',
       │   amount: 0.2  // 20% of position
       │ })
       │
       ▼
┌─────────────┐
│  SWAPPED    │  Alice has: 0.8 NFT-BAYC token
└──────┬──────┘             10 ETH liquidity
       │
       │ STEP 3 (Optional): Redeem NFT later
       │ ────────────────────────────────────
       │ Buy back 0.2 tokens on market
       │ sdk.redeem({ amount: 1.0 })
       │
       ▼
┌─────────────┐
│     END     │  Alice has: BAYC #1234
└─────────────┘             Original NFT back

TIME: ~5 minutes    GAS: ~200k    SLIPPAGE: <1%
```

### Detailed User Personas & Complete Journeys

#### Persona 1: NFT Holder (Alice)

```
╔════════════════════════════════════════════════════════════════╗
║  ALICE: NFT Collector needing liquidity without selling       ║
╚════════════════════════════════════════════════════════════════╝

PROFILE:
• Owns: BAYC #1234 (floor: 50 ETH, ~$150k)
• Need: $30k for down payment
• Problem: Can't sell whole NFT, wants to keep exposure

┌──────────────────────────────────────────────────────────────┐
│                    JOURNEY WITH NFPOOL                        │
└──────────────────────────────────────────────────────────────┘

Day 1, 10:00 AM - Discovery
──────────────────────────────
Alice finds NFPool interface
• Sees BAYC pool with 1.52x backing ratio
• Reads: "Get instant liquidity, keep exposure"
• Decides to try

Day 1, 10:15 AM - Deposit
──────────────────────────────
Opens NFPool dApp → Connect Wallet
    ↓
Select "Deposit NFT"
    ↓
Choose BAYC #1234 from wallet
    ↓
Review Details:
  • Will receive: 1.0 NFT-BAYC token
  • Current value: ~50 ETH
  • Backing ratio: 150%
  • Can redeem anytime
    ↓
Sign transaction (Gas: ~120k, $15)
    ↓
✓ Success: NFT locked in vault
✓ Received: 1.0 NFT-BAYC token

Day 1, 10:20 AM - Swap to USDC
──────────────────────────────
Open Uniswap v4 interface
    ↓
Swap: 0.2 NFT-BAYC → USDC
    ↓
Preview:
  • Input: 0.2 NFT-BAYC
  • Output: ~9,950 USDC (after fees)
  • Slippage: 0.5%
  • Route: Direct (NFPool)
    ↓
Execute swap (Gas: ~150k, $18)
    ↓
✓ Success: Received 9,950 USDC
✓ Remaining: 0.8 NFT-BAYC token

Day 1, 10:25 AM - Check Position
──────────────────────────────
Alice's portfolio:
✓ 9,950 USDC (30k achieved!)
✓ 0.8 NFT-BAYC token (~40 ETH exposure)
✓ Original NFT still redeemable

Day 90, Future - Redeem (Optional)
──────────────────────────────────
BAYC floor rose to 60 ETH
    ↓
Alice's 0.8 tokens now worth 48 ETH
    ↓
Options:
1. Keep tokens (continue exposure)
2. Buy 0.2 tokens back, redeem full NFT
3. Sell all 0.8 tokens for profit

Alice chooses option 2:
    ↓
Buy 0.2 NFT-BAYC on Uniswap (~12 ETH)
    ↓
NFPool dApp → Redeem
    ↓
Burn 1.0 token → Receive BAYC #1234
    ↓
✓ Got original NFT back
✓ Netted ~$30k liquidity for 90 days
✓ Still owns appreciating asset

TOTAL COST: ~$50 gas + ~1% fees
RESULT: Achieved liquidity goal, kept upside exposure
```

#### Persona 2: Trader (Bob)

```
╔════════════════════════════════════════════════════════════════╗
║  BOB: DeFi Trader wanting NFT exposure without custody        ║
╚════════════════════════════════════════════════════════════════╝

PROFILE:
• Capital: 10 ETH (~$30k)
• Thesis: BAYC floor will pump with new game release
• Problem: Can't afford full BAYC (50 ETH)

┌──────────────────────────────────────────────────────────────┐
│                    JOURNEY WITH NFPOOL                        │
└──────────────────────────────────────────────────────────────┘

Day 1 - Enter Position
──────────────────────────────
Opens Uniswap v4
    ↓
Search: "NFT-BAYC" (Collateralized mode)
    ↓
Check pool stats:
  • Backing ratio: 1.52x (over-collateralized)
  • Total NFTs: 45 BAYC in vault
  • 24h volume: 125 ETH
  • Liquidity: $2M
    ↓
Decision: This is backed by real NFTs ✓
    ↓
Buy 0.2 NFT-BAYC with 10 ETH
    ↓
✓ Position: 0.2 NFT-BAYC token (= ~10 BAYC exposure)

Day 1-30 - Monitor
──────────────────────────────
Bob watches:
• BAYC floor: 50 ETH → 65 ETH (+30%)
• His tokens: 10 ETH → 13 ETH (+30%)
• Direct correlation ✓

Day 30 - Exit
──────────────────────────────
Game launches, BAYC pumps to 65 ETH
    ↓
Bob's 0.2 tokens now worth 13 ETH
    ↓
Sell on Uniswap v4
    ↓
✓ Receive: 12.87 ETH (after fees)
✓ Profit: 2.87 ETH (~$8,600)
✓ ROI: 28.7%

ADVANTAGES over buying full BAYC:
• No 50 ETH capital needed
• No custody concerns
• Instant liquidity (vs weeks on marketplace)
• Same price exposure
• Can trade 24/7 on Uniswap

RESULT: Achieved leveraged NFT exposure with DeFi simplicity
```

#### Persona 3: DAO Treasury Manager (Carol)

```
╔════════════════════════════════════════════════════════════════╗
║  CAROL: DAO managing 50 NFT treasury, needs yield             ║
╚════════════════════════════════════════════════════════════════╝

PROFILE:
• DAO: CryptoArtDAO
• Assets: 50 valuable NFTs (Punks, BAYC, Azuki)
• Problem: Assets sitting idle, no yield
• Goal: Earn fees while maintaining exposure

┌──────────────────────────────────────────────────────────────┐
│                    JOURNEY WITH NFPOOL                        │
└──────────────────────────────────────────────────────────────┘

Week 1 - Proposal
──────────────────────────────
Carol proposes to DAO:
"Deploy NFPool for treasury NFTs"

Benefits presented:
✓ Maintain full exposure
✓ Earn trading fees
✓ Increase backing over time
✓ Transparent on-chain accounting
✓ Can redeem anytime via governance

Vote: 95% approval

Week 2 - Deploy Custom Pool
──────────────────────────────
Carol uses NFPool SDK:

const daoPool = await NFPool.create({
  mode: 'HYBRID',
  nftCollection: '0xPunks...',
  backingRatio: 2.0,      // 200% = very safe
  feeModel: 'dynamic',
  strategy: {
    enabled: true,
    buyNFTsOnSurplus: true,  // Accumulate more
    relistMultiplier: 1.15,  // Conservative 15%
    feeThreshold: 1.0        // Only trade with 1+ ETH
  },
  governance: {
    timelock: 7 days,        // DAO needs 7 days to react
    quorum: 30               // 30% needed for decisions
  }
});

await daoPool.deploy();

Week 3 - Deposit Treasury
──────────────────────────────
DAO multisig deposits 50 Punks
    ↓
Each Punk floor: 30 ETH
    ↓
Receive: 50 NFT-PUNK tokens
    ↓
Add 25 tokens + 750 ETH to Uniswap pool
    ↓
✓ Providing liquidity
✓ Earning trading fees
✓ Maintaining 25 tokens (50% exposure)

Month 1-6 - Operation
──────────────────────────────
Pool metrics:
• Trading volume: 500 ETH/month
• Fees earned: 5 ETH/month (1%)
• Strategy: Bought 3 more Punks
• Backing ratio: Now 2.1x (grew from 2.0x)

DAO treasury growth:
  Starting: 50 Punks
  After 6 months: 50 Punks + 3 Punks + 30 ETH fees
  = 53 Punks + 30 ETH

Month 7 - Governance Action
──────────────────────────────
DAO proposes: "Buy more Punks with fees"
    ↓
Vote passes
    ↓
Strategy uses 30 ETH to buy 1 more Punk
    ↓
Total: 54 Punks now

Result: DAO grew holdings from 50 → 54 Punks passively

Year 1 - Success Metrics
──────────────────────────────
✓ Treasury grew: 50 → 58 Punks (+16%)
✓ Fees earned: 60 ETH
✓ Maintained full control (via governance)
✓ Transparent: All on-chain
✓ Community happy: Treasury productive

RESULT: Idle assets now generating yield & growth
```

#### Persona 4: Game Developer (Dave)

```
╔════════════════════════════════════════════════════════════════╗
║  DAVE: Game studio with 10k in-game item NFTs                 ║
╚════════════════════════════════════════════════════════════════╝

PROFILE:
• Company: PixelQuest Studios
• Assets: 10,000 PixelSword NFTs (game items)
• Problem: Players can't sell items, feels locked in
• Goal: Add liquidity to keep players engaged

┌──────────────────────────────────────────────────────────────┐
│                    JOURNEY WITH NFPOOL                        │
└──────────────────────────────────────────────────────────────┘

Sprint 1 - Integration Planning
──────────────────────────────────
Dave's team evaluates options:

Option A: Build custom marketplace
  ⚠ Takes 3 months
  ⚠ Must maintain order books
  ⚠ Fragmented liquidity

Option B: Use NFPool
  ✓ SDK integration: 1 week
  ✓ Instant AMM liquidity
  ✓ Uniswap composability

Decision: NFPool ✓

Sprint 2 - Development
──────────────────────────────────
Backend developer integrates:

import { NFPool } from '@nfpool/sdk';

// Deploy pool for PixelSwords
const gamePool = await NFPool.create({
  mode: 'COLLATERALIZED',
  nftCollection: contracts.PixelSword,
  backingRatio: 1.1,        // Low backing = more mints
  feeModel: 'fixed',        // Predictable 0.3%
  vault: {
    minDeposit: 1,
    redemptionFee: 0        // No fee for players
  }
});

// Frontend: Add "Sell Item" button
async function sellItem(itemId) {
  // Deposit → Mint → Swap in one flow
  const tx = await gamePool.depositAndSwap({
    nftId: itemId,
    outputToken: 'USDC',
    minOutput: expectedUSDC * 0.95  // 5% slippage
  });
  return tx;
}

Sprint 3 - Launch
──────────────────────────────────
Game update v2.5:
"Introducing: Instant Item Sales"

New UI:
┌────────────────────────┐
│  Your PixelSword #1234 │
│  Floor: 0.1 ETH        │
│                        │
│  [Sell for USDC]       │  ← New button
│   ~$300 instant        │
└────────────────────────┘

Month 1 - Player Feedback
──────────────────────────────────
Player reviews:
⭐⭐⭐⭐⭐ "Finally can cash out items!"
⭐⭐⭐⭐⭐ "Instant sale, no waiting for buyers"
⭐⭐⭐⭐⭐ "Better than any game marketplace"

Metrics:
• 500 items sold first month
• $150k volume
• Players reinvest in game
• Retention up 25%

Month 6 - Expansion
──────────────────────────────────
Studio launches 3 more item types:
• PixelShield → NFPool
• PixelArmor → NFPool
• PixelHelm → NFPool

All items now have instant liquidity

Year 1 - Network Effects
──────────────────────────────────
Other games notice:
• "PixelQuest has liquid items"
• Players prefer games with liquidity
• 5 studios integrate NFPool

Result: NFPool becomes standard for game NFTs

BUSINESS IMPACT:
• Player satisfaction up 35%
• Item sales up 10x
• Integration cost: 1 developer-week
• Maintenance: Zero (protocol handles it)

RESULT: From illiquid game items to instant tradeable assets
```

#### Persona 5: Developer Deploying Pool (Eve)

```
╔════════════════════════════════════════════════════════════════╗
║  EVE: Community member launching pool for new collection      ║
╚════════════════════════════════════════════════════════════════╝

PROFILE:
• Role: Community organizer
• Project: GoblinPunks (new 5k collection)
• Problem: No liquidity, holders can't trade
• Goal: Launch permissionless pool

┌──────────────────────────────────────────────────────────────┐
│              COMPLETE DEPLOYMENT JOURNEY                      │
└──────────────────────────────────────────────────────────────┘

Day 1, Hour 1 - Setup Environment
──────────────────────────────────────
Terminal:
$ npm init -y
$ npm install @nfpool/sdk ethers

Day 1, Hour 2 - Write Deployment Script
──────────────────────────────────────
File: deploy-goblin-pool.js

import { NFPool } from '@nfpool/sdk';
import { ethers } from 'ethers';

async function main() {
  // Connect wallet
  const provider = new ethers.JsonRpcProvider(BASE_RPC);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

  console.log('Deploying pool for GoblinPunks...');

  // Create pool config
  const pool = await NFPool.create({
    signer: wallet,
    chain: 'base',
    mode: 'SPECULATIVE',  // No NFTs needed to start
    nftCollection: '0xGoblinPunks...',
    tokenName: 'GoblinPunk Exposure',
    tokenSymbol: 'GOBLIN',
    initialPrice: ethers.parseEther('0.01'),  // Start at 0.01 ETH
    strategy: {
      enabled: true,
      buyNFTsOnSurplus: true,
      relistMultiplier: 1.3,  // 30% markup
      marketplaces: ['opensea', 'blur']
    }
  });

  // Deploy
  const tx = await pool.deploy();
  await tx.wait();

  console.log('✓ Pool deployed:', pool.address);
  console.log('✓ Token:', pool.tokenAddress);
  console.log('✓ Strategy:', pool.strategyAddress);
}

main();

Day 1, Hour 3 - Deploy
──────────────────────────────────────
Terminal:
$ node deploy-goblin-pool.js

Output:
Deploying pool for GoblinPunks...
  → Deploying hook... (tx: 0xabc...)
  → Deploying vault... (tx: 0xdef...)
  → Deploying strategy... (tx: 0x123...)
  → Initializing pool... (tx: 0x456...)
✓ Pool deployed: 0x7890...
✓ Token: 0xabcd...
✓ Strategy: 0xef01...

Total gas: ~$50
Time: 3 minutes

Day 1, Hour 4 - Add Initial Liquidity
──────────────────────────────────────
Eve adds liquidity:
• 1 ETH
• 100 GOBLIN tokens (1 ETH worth)

Uniswap v4 pool now live ✓

Day 1, Hour 5 - Announce to Community
──────────────────────────────────────
Discord:
"🎉 GoblinPunk token is LIVE!

Pool: 0x7890...
Token: GOBLIN
Mode: Speculative (fees buy GoblinPunks)

Trade now: [Uniswap link]
As we trade, strategy will:
1. Accumulate fees
2. Buy GoblinPunks from floor
3. Relist at 30% markup
4. Burn tokens with profits

Let's pump the floor together! 🚀"

Day 2-7 - Community Growth
──────────────────────────────────────
• 50 holders buy GOBLIN tokens
• Volume: 25 ETH
• Fees: 0.25 ETH
• Strategy: Bought first GoblinPunk #234

Day 30 - Success Metrics
──────────────────────────────────────
Pool stats:
✓ 500 holders
✓ $100k volume
✓ 5 GoblinPunks acquired
✓ 2 GoblinPunks sold at profit
✓ 50k GOBLIN tokens burned
✓ Token price: 0.01 → 0.015 ETH (+50%)

Community: "This actually works!"

RESULT: Permissionless pool launch in 5 hours, no dev team needed
```

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
