# Week 3: Office Hours - Security Framework & Design Philosophy

**Author**: Allan Robinson
**Date**: February 2, 2026 (Monday)
**Context**: Pre-Week 3 office hours session

---

## Session Overview

Today's office hours covered critical topics before our official Week 3 class tomorrow. We explored the security framework, discussed advanced hook design patterns, and examined real-world implementations like Clanker v4. This session was particularly valuable as it bridged theoretical knowledge with practical security considerations.

---

## Security Framework Deep Dive

The Uniswap Foundation provides a **self-directed security framework** for V4 hook developers. This is not a certification program but rather a comprehensive risk assessment tool.

### Key Principle

> "The framework is provided as a public, informational resource and does not represent security assurances or guarantees of safety."

This means **we are responsible** for our own security decisions. The framework guides us, but doesn't certify our work.

### The 9 Risk Dimensions

Every hook must be scored across these dimensions:

```
┌─────────────────────────────────────────────────────────────┐
│                    RISK SCORING MATRIX                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Complexity (0-5)          Code branching, callbacks    │
│  2. Custom Math (0-5)         Curves, TWAMM, logarithms    │
│  3. External Dependencies (0-3) Oracles, lending, bridges  │
│  4. External Liquidity (0-3)  Holdings in other protocols  │
│  5. TVL Potential (0-5)       <$100K to $50M+              │
│  6. Team Maturity (0-3)       Production experience        │
│  7. Upgradeability (0-3)      Proxy complexity             │
│  8. Autonomous Updates (0-3)  Self-tuning parameters       │
│  9. Price Impact (0-3)        Fee/routing modifications    │
│                                                             │
│  TOTAL SCORE: 0-33 points                                  │
│                                                             │
│  LOW RISK:    0-6   points                                 │
│  MEDIUM RISK: 7-17  points                                 │
│  HIGH RISK:   18-33 points                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Risk Tiers & Requirements

#### Low Risk (0-6 Points)
- **Audit**: One full audit + AI static analysis
- **Math Specialist**: Not required
- **Bug Bounty**: Optional
- **Monitoring**: Optional unless TVL grows

**Example**: Simple swap counter hook with no external calls.

#### Medium Risk (7-17 Points)
- **Audit**: One full audit (optional second for complex math)
- **Bug Bounty**: Recommended
- **Monitoring**: Recommended with external dependencies
- **Additional Testing**: Autonomy features need extra coverage

**Example**: Points hook with oracle price feeds.

#### High Risk (18-33 Points)
- **Audit**: **Two formal audits** (one must be math specialist)
- **Bug Bounty**: **Mandatory**
- **Testing**: Invariants + stateful fuzzing **required**
- **Monitoring**: **Mandatory** with anomaly detection
- **Formal Verification**: Optional for invariant validation

**Example**: Custom bonding curve hook with autonomous rebalancing.

### The 5 Critical Risk Categories

#### 1. Accounting & Token Handling

**Risk**: Incorrect delta calculations, unexpected token behaviors.

```solidity
// WRONG: Assumes 1:1 token transfer
function afterSwap(...) {
    userBalance[sender] += amountIn;  // ❌ Fee-on-transfer?
}

// RIGHT: Validate actual received amount
function afterSwap(...) {
    uint256 balanceBefore = token.balanceOf(address(this));
    token.transferFrom(sender, address(this), amountIn);
    uint256 actualReceived = token.balanceOf(address(this)) - balanceBefore;
    userBalance[sender] += actualReceived;  // ✅ Accurate
}
```

**Framework warning**: "Small errors can cascade into large systemic failures."

#### 2. External Interactions & Reentrancy

**Risk**: State corruption during callbacks, nested operations.

```
┌─────────────────────────────────────────┐
│         REENTRANCY ATTACK FLOW          │
├─────────────────────────────────────────┤
│                                         │
│  1. User calls swap()                   │
│     ↓                                   │
│  2. Hook's afterSwap() executes         │
│     ↓                                   │
│  3. Hook calls external contract        │
│     ↓                                   │
│  4. External contract calls back        │
│     into hook (REENTERS)                │
│     ↓                                   │
│  5. Hook state is inconsistent          │
│     ↓                                   │
│  6. Exploit drains funds                │
│                                         │
└─────────────────────────────────────────┘
```

**Protection pattern**:
```solidity
// Use checks-effects-interactions pattern
function afterSwap(...) internal override {
    // 1. CHECKS
    require(sender != address(0), "Invalid sender");

    // 2. EFFECTS (update state first)
    userPoints[sender][poolId] += POINTS_PER_SWAP;

    // 3. INTERACTIONS (external calls last)
    if (shouldNotify) {
        externalOracle.notify(sender, points);  // Safe
    }
}
```

#### 3. Mathematical Correctness

**Risk**: Custom curves, precision drift, invariant discontinuities.

The framework identifies this as requiring **specialist review** when hooks implement:
- Custom bonding curves
- TWAMM (Time-Weighted Average Market Maker)
- Non-standard AMM math
- Logarithmic calculations

**Example risk**: Rounding errors accumulating over thousands of swaps.

```solidity
// DANGEROUS: Repeated division causes drift
uint256 fee = (amount * 30) / 10000;  // 0.3% fee
uint256 afterFee = amount - fee;
// After 1000 iterations, could lose significant value to rounding

// BETTER: Use FullMath library
uint256 fee = FullMath.mulDiv(amount, 30, 10000);
```

#### 4. External Dependencies

**Risk**: Oracles, lending protocols, bridges can fail mid-execution.

**Failure modes**:
- Stale pricing from oracles
- Reverts from external protocols
- Liquidity changes during callbacks

**My question from office hours**: How to handle oracle failures gracefully?

**Answer**: Implement circuit breakers and fallback mechanisms:

```solidity
function getPrice() internal view returns (uint256) {
    try oracle.latestRoundData() returns (
        uint80 roundId,
        int256 price,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        // Check freshness
        require(block.timestamp - updatedAt < 1 hours, "Stale price");
        require(price > 0, "Invalid price");
        return uint256(price);
    } catch {
        // Fallback: Use TWAP or pause
        return getTWAP();  // Or revert to halt trading
    }
}
```

#### 5. Upgradeability Hazards

**Risk**: Proxy patterns introduce storage layout vulnerabilities.

**Framework recommendation**: "Prefer immutability and use standard patterns with multisig/timelock controls."

```
┌─────────────────────────────────────────┐
│       PROXY STORAGE COLLISION           │
├─────────────────────────────────────────┤
│                                         │
│  BEFORE UPGRADE:                        │
│  slot 0: owner (address)                │
│  slot 1: paused (bool)                  │
│  slot 2: feeRate (uint256)              │
│                                         │
│  AFTER UPGRADE (WRONG ORDER):           │
│  slot 0: paused (bool)                  │
│  slot 1: owner (address)     ❌ BROKEN │
│  slot 2: newFeature (uint256)           │
│                                         │
│  Result: Owner address corrupted!       │
│                                         │
└─────────────────────────────────────────┘
```

**Best practice**: Use OpenZeppelin's upgradeable contracts with gap variables.

---

## Feature-Specific Security Triggers

Certain features **mandate** additional security measures regardless of risk score:

### Custom Math Triggers

If your hook has custom curves or non-standard math:
- ✅ **Required**: Math specialist audit
- ✅ **Required**: Unit tests for edge cases
- ✅ **Recommended**: Formal verification if TVL = 5

### TVL = 5 Triggers ($10M+)

If your hook expects $10M+ TVL:
- ✅ **Mandatory**: Continuous monitoring
- ✅ **Mandatory**: Bug bounty program
- ✅ **Recommended**: Formal verification
- ✅ **Required**: Emergency procedures (pause/kill-switch)

### Price Impact Triggers

If your hook modifies fees or routing:
- ✅ **Required**: Math specialist audit
- ✅ **Mandatory**: Bug bounty
- ✅ **Required**: Monitoring if TVL = 5

---

## Universal Best Practices Checklist

From the security framework, these apply to **every hook**:

### Core Controls
- [ ] Minimal, clearly-defined access control
- [ ] Reentrancy protection on all external paths
- [ ] Checks-effects-interactions pattern everywhere
- [ ] Use OpenZeppelin libraries (audited code)
- [ ] Gas/balance griefing protections

### Accounting Safety
- [ ] Validate rounding behavior
- [ ] Test delta validation for every callback
- [ ] Invariant checks for consistency
- [ ] Safe token return handling
- [ ] Track unbounded dynamic state

### Transparency
- [ ] Publish all audit reports with versions
- [ ] Maintain transparent changelog
- [ ] Provide active disclosure contact (security@...)

---

## Security Tools & Resources

The framework recommends these tools:

### Testing Frameworks
- **Foundry**: Unit tests, fuzz tests, invariant tests
- **Echidna**: Property-based testing
- **Hacken V4 Hook Framework**: Hook-specific testing

### Formal Verification
- **Certora**: Prover for Solidity
- **Halmos**: Symbolic execution
- **SMTChecker**: Built into Solidity compiler

### Monitoring Services
- **Hypernative**: Real-time anomaly detection
- **Hexagate**: On-chain security monitoring

### Audit Firms
- **Spearbit**: Specialized in DeFi
- **Code4rena**: Competitive audits
- **OpenZeppelin**: Comprehensive audits
- **Areta**: Hook specialists

---

## My Security Assessment Process

Based on today's office hours, here's how I'll approach security:

### Step 1: Self-Score (15 minutes)

Use the [risk calculator](https://docs.google.com/spreadsheets/d/1oZdKZh13UbqVp3HujAcv-2NKP-j7NQAELhB7kyWlLRE/edit) to score my hook across 9 dimensions.

### Step 2: Identify Tier + Triggers (5 minutes)

- Calculate total score → Tier (low/medium/high)
- Check feature flags (custom math? TVL 5? Upgradeability?)
- Combine requirements

### Step 3: Plan Security Measures (30 minutes)

- List required audits
- Set up testing infrastructure
- Design monitoring strategy
- Create OPSEC procedures

### Step 4: Implement & Document (ongoing)

- Write comprehensive tests (>90% coverage)
- Document all assumptions
- Prepare for audit (clear code comments)
- Set up bug bounty when appropriate

### Step 5: Continuous Reassessment

- Review before each deployment
- Reassess when TVL grows
- Update after any upgrades

---

## Clanker v4: Real-World Security Case Study

During office hours, we discussed Clanker as an example of production-ready hook architecture.

### What is Clanker?

Clanker is a **modular token launcher** built on Uniswap V4. It demonstrates how to architect complex hook systems securely.

### Core Architecture

```
┌─────────────────────────────────────────────────┐
│              CLANKER V4 SYSTEM                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────┐         ┌────────────────┐       │
│  │ Clanker  │────────▶│ ClankerToken   │       │
│  │ Factory  │         │ (ERC20)        │       │
│  └──────────┘         └────────────────┘       │
│       │                                         │
│       │  Creates pools & positions liquidity   │
│       ▼                                         │
│  ┌──────────────────────────────┐              │
│  │    PoolManager (V4 Core)     │              │
│  └──────────────────────────────┘              │
│       │                                         │
│       │  Executes hooks                        │
│       ▼                                         │
│  ┌──────────────────────────────┐              │
│  │    ClankerHook               │              │
│  │    - Base                    │              │
│  │    - StaticFee               │              │
│  │    - DynamicFee              │              │
│  └──────────────────────────────┘              │
│       │                                         │
│       │  Optional extensions                   │
│       ▼                                         │
│  ┌──────────────────────────────┐              │
│  │  IClankerExtensions          │              │
│  │  - ClankerVault (vesting)    │              │
│  │  - ClankerAirdrop            │              │
│  │  - MEV protection            │              │
│  └──────────────────────────────┘              │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Key Design Patterns

#### 1. Interface-Based Modularity

Clanker defines **four interfaces** that implementations must satisfy:

```solidity
interface IClankerLpLocker {
    // Manages liquidity placement and fee distribution
}

interface IClankerExtensions {
    // Adds supplementary functionality
}

interface IClankerMevModule {
    // Chain-specific MEV protection
}

interface IClankerHook {
    // Uniswap v4 Hooks compatibility
}
```

**Why this matters**: Separating concerns makes each component auditable independently.

#### 2. Non-Upgradeable Core

The three core contracts are **immutable**:
- Clanker (factory)
- ClankerFeeLocker
- ClankerToken

**Security benefit**: No storage collision risks, no proxy vulnerabilities.

**Trade-off**: Must deploy new versions for major changes (acceptable for security-critical code).

#### 3. Allowlist System

Extensions must be **allowlisted** before use. This creates a security perimeter.

**My question**: How does the allowlist process work?

**Answer from office hours**:
1. Developer submits extension contract
2. Clanker team reviews code
3. Security assessment (similar to Uniswap framework)
4. Allowlist decision (multisig controlled)
5. If approved, extension can be used by any token

This is similar to how Uniswap will manage hook allowlists on mainnet.

### MEV Protection Strategies

Clanker implements **multiple MEV defense options**:

#### Option 1: Simple 2-Block Delay
```solidity
mapping(address => uint256) lastSwapBlock;

function beforeSwap(...) external returns (bytes4, BeforeSwapDelta, uint24) {
    require(
        block.number > lastSwapBlock[sender] + 2,
        "Too soon"
    );
    lastSwapBlock[sender] = block.number;
    // Continue with swap
}
```

**Pro**: Simple, effective against basic sandwich attacks.
**Con**: Poor UX (users wait ~24 seconds).

#### Option 2: Descending Fee Auction

```
┌─────────────────────────────────────────┐
│      DESCENDING FEE AUCTION (DFA)       │
├─────────────────────────────────────────┤
│                                         │
│  Fee %                                  │
│    │                                    │
│  80│●                                   │
│    │ ●                                  │
│  60│  ●●                                │
│    │    ●●                              │
│  40│      ●●●                           │
│    │         ●●●                        │
│  20│            ●●●●                    │
│    │                ●●●●●●              │
│   0│                      ●●●●●●●●●     │
│    └────────────────────────────────────▶
│         Blocks since pool creation      │
│    0    10    20    30    40    50      │
│                                         │
└─────────────────────────────────────────┘
```

**How it works**:
1. New token pool starts with 80% swap fee
2. Fee decays parabolically over N blocks
3. Eventually reaches normal fee (0.3%)
4. Snipers pay massive fees early, protecting fair launch

**Tunable parameters**:
- Starting fee (default: 80%)
- Decay duration (configurable blocks)
- Curve shape (linear, parabolic, exponential)

**Result**: Bots are disincentivized; humans wait for fair price.

---

## Design Philosophy: Questions from Office Hours

### Question 1: "Should every hook have an admin role?"

**Discussion**: Admin roles add flexibility but introduce centralization.

**Framework perspective**:
- **Minimal access control** is preferred
- If admin exists:
  - Must use multisig (5+ signers)
  - Must use timelock (48+ hours)
  - Must have public upgrade policy

**My approach**:
- For learning hooks: No admin (fully immutable)
- For production: Admin only for emergency pause
- For advanced: Consider progressive decentralization

```solidity
// Good: Minimal admin for emergency only
address public immutable admin;
bool public paused;

function pause() external {
    require(msg.sender == admin, "Only admin");
    paused = true;
    emit Paused(block.timestamp);
}

// No unpause function - requires new deployment
// No other admin powers
```

### Question 2: "How do I know if my hook idea is too complex?"

**Rule of thumb from office hours**:

```
Complexity Score =
    (number of hook functions used) +
    (2 × external dependencies) +
    (3 × custom math implementations) +
    (2 × if upgradeability)

If score > 10: Consider splitting into multiple hooks
```

**Example**: My anti-MEV hook
- 2 hook functions (beforeSwap, afterSwap) = 2
- 0 external dependencies = 0
- 0 custom math = 0
- 0 upgradeability = 0
- **Total: 2 (LOW complexity)** ✅

**Example**: Complex DeFi optimizer hook
- 4 hook functions = 4
- 3 external dependencies (oracle, lending, DEX) = 6
- 2 custom math (bonding curve, rebalancing) = 6
- 1 upgradeability (proxy) = 2
- **Total: 18 (HIGH complexity)** ⚠️ Consider splitting

### Question 3: "When should I use events vs storage?"

**Answer from security perspective**:

| Use Case | Storage | Events |
|----------|---------|--------|
| Smart contract logic needs it | ✅ Yes | Optional |
| Only frontend/indexer needs it | ❌ No | ✅ Yes |
| Historical queries needed | ❌ No | ✅ Yes |
| Gas optimization critical | ❌ No | ✅ Yes |

**Storage**: ~20,000 gas for new slot
**Event**: ~1,500 gas per topic

**Example from PointsHook**:
```solidity
// Storage: Current points (contracts need this)
mapping(address => mapping(PoolId => uint256)) public userPoints;

// Events: Historical activity (only frontends need this)
event PointsAwarded(address indexed user, PoolId indexed poolId, uint256 points);
```

---

## Hook Allowlist Process

One of the most important topics from office hours: **How do hooks get approved for mainnet?**

### The Allowlist System

Uniswap V4 on mainnet will have **permissioned hook deployment** initially. Not every hook can be used.

```
┌─────────────────────────────────────────┐
│       HOOK ALLOWLIST WORKFLOW           │
├─────────────────────────────────────────┤
│                                         │
│  1. Developer builds hook               │
│     ↓                                   │
│  2. Self-assess using framework         │
│     ↓                                   │
│  3. Complete security requirements      │
│     (audits, tests, etc.)               │
│     ↓                                   │
│  4. Submit to Uniswap Foundation        │
│     ↓                                   │
│  5. Foundation reviews:                 │
│     - Risk score accuracy               │
│     - Audit quality                     │
│     - Test coverage                     │
│     - OPSEC procedures                  │
│     ↓                                   │
│  6. Decision:                           │
│     ✅ Approved → Add to allowlist      │
│     ⏳ Pending → Address feedback       │
│     ❌ Rejected → Fix issues & resubmit │
│                                         │
└─────────────────────────────────────────┘
```

### What Foundation Reviews

Based on office hours discussion:

1. **Risk Assessment Accuracy**
   - Did you score honestly?
   - Are all features disclosed?

2. **Security Completion**
   - All required audits done?
   - Bug bounty established (if required)?
   - Test coverage >90%?

3. **Code Quality**
   - Clean, documented code?
   - Standard patterns used?
   - Gas optimized?

4. **Operational Security**
   - Admin controls appropriate?
   - Emergency procedures documented?
   - Upgrade policy public?

5. **Economic Soundness**
   - Fee model sustainable?
   - No extractive mechanics?
   - Aligned with ecosystem health?

### Timeline Expectations

**Not official, based on discussion**:

- Low risk hooks: ~2-4 weeks review
- Medium risk: ~4-8 weeks
- High risk: ~8-12 weeks (multiple review rounds)

**Tip**: Start allowlist process early, even before full implementation.

---

## My Personal Hook Questions

During office hours, I asked about potential hook ideas I've been thinking about:

### Idea 1: NFT Arbitrage Hook

**Concept**: Hook that monitors NFT floor prices and automatically rebalances liquidity when arbitrage opportunities exist.

**How it would work**:
```
1. Hook monitors Uniswap pool (e.g., APE/ETH)
2. Hook also watches NFT floor prices (Reservoir API)
3. If floor price < pool price × slippage threshold:
   → Opportunity to buy NFT, sell APE tokens
4. Hook could signal this to arbitrageurs
5. Hook earns fee on successful arbitrages
```

**Security concerns raised**:
- Oracle dependency (NFT floor prices) = Medium Risk
- External interactions (NFT marketplaces) = Medium Risk
- **Risk score**: Likely 12-15 (Medium Risk)
- **Requirements**: One audit, bug bounty recommended

### Idea 2: Donation/Philanthropy Hook

**My question**: "Could a hook route a small percentage of swap fees to charitable causes?"

**Discussion points**:

✅ **Technically possible**:
```solidity
function afterSwap(...) internal override returns (bytes4, int128) {
    // Calculate fee (e.g., 0.1% of swap)
    uint256 donationAmount = calculateDonation(delta);

    // Route to charity address
    charityVault.deposit(donationAmount);

    emit DonationMade(sender, charityAddress, donationAmount);

    return (BaseHook.afterSwap.selector, 0);
}
```

✅ **User opt-in**: Could be explicit (users choose pools with donation hook)

⚠️ **Challenges**:
- **Trust**: How to verify charity receives funds?
- **Tax implications**: Donations on behalf of users?
- **Regulatory**: Securities concerns if "charity token" used?

**Potential solution**: Partner with established on-chain charity protocols (Gitcoin, Endaoment)

**Connection to my background**: I mentioned my paper on Creator Coins and this relates to community-aligned incentives.

### Idea 3: Agentic AI Integration (Clanker Style)

**Concept**: Hooks that respond to AI agent commands for automated trading strategies.

**How Clanker does this**:
- AI toolkit provides structured interface
- Agents can deploy tokens via API
- Hooks manage liquidity automatically
- MEV protection built-in

**My variation**: AI agents that manage LP positions
- Agent monitors market conditions
- Adjusts liquidity ranges automatically
- Rebalances based on volatility
- Hooks enforce agent permissions

**Security considerations**:
- Agent key management (OPSEC critical)
- Rate limiting (prevent AI spam)
- Circuit breakers (if AI misbehaves)
- **High complexity** - would need extensive testing

---

## Account Abstraction & Gas-Free Swaps

Another advanced topic we touched on: **Making DeFi accessible through gasless transactions**.

### The Problem

Current DeFi friction:
```
User wants to swap USDC → ETH

❌ But user has no ETH for gas!

Traditional solution:
1. User must first acquire ETH
2. Then can swap USDC → ETH

This is terrible UX.
```

### Account Abstraction Solution

**ERC-4337** enables programmable wallets that can:
- Pay gas in any token (not just ETH)
- Have sponsors pay gas for them
- Bundle multiple operations

```
┌─────────────────────────────────────────┐
│      ACCOUNT ABSTRACTION FLOW           │
├─────────────────────────────────────────┤
│                                         │
│  User                                   │
│    │                                    │
│    │ "Swap 100 USDC → ETH"              │
│    ▼                                    │
│  Smart Wallet (ERC-4337)                │
│    │                                    │
│    │ Creates UserOperation:             │
│    │ - swap(100 USDC)                   │
│    │ - paymaster: SponsorContract       │
│    ▼                                    │
│  Bundler                                │
│    │                                    │
│    │ Submits to blockchain              │
│    ▼                                    │
│  EntryPoint Contract                    │
│    │                                    │
│    │ Validates & executes               │
│    ├────────▶ Uniswap V4                │
│    │          (swap happens)            │
│    │                                    │
│    └────────▶ Paymaster                 │
│              (sponsor pays gas)         │
│                                         │
└─────────────────────────────────────────┘
```

### Gelato's Implementation

From my research: [Gelato Account Abstraction](https://gelato.cloud/blog/gasless-transactions-gelato-safe-account-abstraction)

**Key stats**:
- 25.5M smart accounts created
- 132M UserOps executed
- ~$5.7M in sponsored gas fees
- Support for 100+ chains

**How it works with Uniswap**:
1. User signs swap intent (off-chain, free)
2. Gelato's Paymaster sponsors gas
3. Swap executes on Uniswap V4
4. Optional: Paymaster recoups cost from swap output

**Hook opportunity**:
```solidity
// GaslessSwapHook
// - Integrates with Gelato Paymaster
// - Deducts small fee from swap output to cover gas
// - User experience: totally gasless
```

### EIP-7702 (Future)

**Even better**: Upgrade existing EOAs to smart accounts

**Before (ERC-4337)**: Users must create new smart wallet
**After (EIP-7702)**: Your existing wallet becomes programmable

**Impact for hooks**:
- Easier user onboarding
- No "move funds to new address" step
- Better compatibility with existing apps

---

## Bonding Curves & Liquidity Bootstrapping

During office hours, we discussed **fair launch mechanisms** - highly relevant for new token launches.

### Traditional Token Launch Problems

```
Problem 1: Snipers
- Bots buy entire supply in first block
- Retail gets terrible prices

Problem 2: Whales
- Large holders manipulate price
- Creates centralization

Problem 3: Price Discovery
- Hard to find fair initial price
- Often leads to pump & dump
```

### Liquidity Bootstrapping Pools (LBPs)

**Concept**: Pool weights change over time to discourage early buying.

```
┌─────────────────────────────────────────┐
│    LBP WEIGHT SHIFT (48 hours)          │
├─────────────────────────────────────────┤
│                                         │
│  Start (Hour 0):                        │
│  ┌────────────────────────┬──┐         │
│  │   NEW_TOKEN (95%)      │E │         │
│  │                        │T │         │
│  │                        │H │         │
│  │                        │5%│         │
│  └────────────────────────┴──┘         │
│                                         │
│  Price: HIGH (discourages buying)       │
│                                         │
│  ─────────────────────────────          │
│                                         │
│  Middle (Hour 24):                      │
│  ┌──────────────┬───────────┐          │
│  │  NEW_TOKEN   │    ETH    │          │
│  │    (50%)     │   (50%)   │          │
│  └──────────────┴───────────┘          │
│                                         │
│  Price: MEDIUM (getting fairer)         │
│                                         │
│  ─────────────────────────────          │
│                                         │
│  End (Hour 48):                         │
│  ┌──┬────────────────────────┐         │
│  │N │      ETH (80%)         │         │
│  │E │                        │         │
│  │W │                        │         │
│  │20│                        │         │
│  └──┴────────────────────────┘         │
│                                         │
│  Price: FAIR MARKET VALUE               │
│                                         │
└─────────────────────────────────────────┘
```

**Key insight**: Users are incentivized to **wait** for the price to drop rather than buy early.

### Mathematical Model

From my research: [Balancer LBP Documentation](https://docs.balancer.fi/concepts/explore-available-balancer-pools/liquidity-bootstrapping-pool.html)

**Price formula**:
```
P = (Reserve_NEW / Weight_NEW) / (Reserve_ETH / Weight_ETH)

As Weight_NEW decreases and Weight_ETH increases,
Price decreases even if reserves stay constant.
```

**Example**:
```
Start: 1,000,000 NEW tokens, 10 ETH
Weights: 95% / 5%
Price = (1,000,000 / 0.95) / (10 / 0.05)
      = 1,052,632 / 200
      = 5,263 NEW per ETH

End: Same reserves (no trades)
Weights: 20% / 80%
Price = (1,000,000 / 0.20) / (10 / 0.80)
      = 5,000,000 / 12.5
      = 400,000 NEW per ETH

Price dropped 92% with zero trades!
```

### Hook Implementation Strategy

**V4 doesn't have native weight-shifting, but hooks can simulate it**:

```solidity
// LBP Hook concept
function beforeSwap(...) external view returns (bytes4, BeforeSwapDelta, uint24) {
    // Calculate time-based fee adjustment
    uint256 launchTime = poolLaunchTime[poolId];
    uint256 elapsed = block.timestamp - launchTime;

    if (elapsed < LBP_DURATION) {
        // Early buyers pay higher "fee" (simulates high price)
        // Fee decays linearly
        uint256 extraFee = calculateDecayingFee(elapsed);

        // Fee goes to LP providers (discourages sniping)
        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            uint24(extraFee)
        );
    }

    // After LBP period: normal fee
    return (
        BaseHook.beforeSwap.selector,
        BeforeSwapDeltaLibrary.ZERO_DELTA,
        3000  // 0.3%
    );
}
```

**Benefits for Uniswap V4**:
- Fair token launches
- Reduced bot activity
- Better distribution
- More sustainable projects

---

## Key Takeaways from Office Hours

### 1. Security is Not Optional

The framework is comprehensive for a reason. Every dimension matters. I need to:
- Score honestly
- Meet all requirements for my risk tier
- Not cut corners on audits or testing

### 2. Start Simple, Scale Carefully

**My plan**:
- **Week 3-4**: Build simple hooks (low risk)
- **Week 5-6**: Add moderate complexity (medium risk)
- **Week 7-8**: Tackle advanced features (high risk)

Don't jump to complex designs too early.

### 3. Learn from Production Examples

Clanker demonstrates:
- Clean architecture (interface-based)
- Security-first design (immutable core)
- User protection (MEV defenses)
- Extensibility (allowlist system)

I should study more production hooks for patterns.

### 4. Community and Ecosystem Matter

The allowlist process shows hooks don't exist in isolation. I need to:
- Engage with community
- Share my work early
- Get feedback from experienced developers
- Build reputation for security consciousness

### 5. My Hook Ideas Are Viable

The discussion validated several of my concepts:
- ✅ NFT arbitrage: Possible (medium risk)
- ✅ Donation hooks: Possible (some challenges)
- ✅ AI integration: Possible (high complexity)

Next step: Prototype the simplest version of each.

---

## Action Items for Tomorrow's Class

Before Week 3 Session 1 (Tuesday), I will:

1. **Review security framework spreadsheet**
   - Download risk calculator
   - Practice scoring example hooks

2. **Study Clanker codebase**
   - Read ClankerHook implementation
   - Understand extension interface pattern

3. **Brainstorm hook variations**
   - NFT arbitrage (simple version)
   - Donation hook (MVP)
   - LBP hook (mathematical model)

4. **Prepare questions**
   - How to test oracle failures?
   - Best practices for gas optimization?
   - When to use BeforeSwapDelta vs AfterSwapDelta?

---

## Resources & Links

### Security Framework
- [Uniswap V4 Security Docs](https://docs.uniswap.org/contracts/v4/security)
- [Risk Calculator Spreadsheet](https://docs.google.com/spreadsheets/d/1oZdKZh13UbqVp3HujAcv-2NKP-j7NQAELhB7kyWlLRE/edit)

### Clanker
- [Clanker V4 Documentation](https://clanker.gitbook.io/clanker-documentation/references/core-contracts/v4)
- [Clanker GitHub](https://github.com/Uniswap/clanker) *(if public)*

### Account Abstraction
- [Gelato Account Abstraction](https://gelato.cloud/blog/gasless-transactions-gelato-safe-account-abstraction)
- [ERC-4337 Overview](https://docs.gelato.cloud/web3-services/account-abstraction)
- [Alchemy's AA Guide](https://www.alchemy.com/account-abstraction)

### Bonding Curves & LBPs
- [Balancer LBP Docs](https://docs.balancer.fi/concepts/explore-available-balancer-pools/liquidity-bootstrapping-pool.html)
- [Bonding Curve Primer](https://defiprime.com/bonding-curve-explained)
- [Fjord Foundry (LBP Platform)](https://fjordfoundry.com/)

### NFT + DeFi
- [Awesome Uniswap Hooks](https://github.com/fewwwww/awesome-uniswap-hooks) - includes NFT examples

---

## Personal Reflections

This is my **first web3 job** and today's office hours made me realize how much the community values security and responsibility. Coming from my academic background (Creator Coins paper), I'm excited to apply economic theory to real protocol design.

The discussion about donation hooks particularly resonated with me. Crypto's promise of transparent, programmable value transfer could revolutionize philanthropy. Imagine:
- Every DEX swap contributes 0.01% to verified charities
- Complete transparency (all on-chain)
- Users choose causes they care about
- No middlemen extracting fees

This feels like genuinely impactful work, not just financial engineering.

Next step: Build something that matters.

---

**Allan Robinson**
Office Hours Week 3 - February 2, 2026

