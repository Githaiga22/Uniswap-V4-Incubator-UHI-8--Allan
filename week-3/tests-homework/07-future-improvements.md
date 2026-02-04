# Future Improvements

**Assignment**: UHI Custom Pricing Curve Hook Quest
**Student**: Allan Robinson
**Date**: February 3, 2026

---

## Overview

While the current InternalSwapPool implementation is functional and production-ready, there are several enhancements that could make it even more powerful and flexible.

---

## Short-Term Improvements (Week 4-8)

### 1. Pool Validation in beforeInitialize

**Current**: Hook accepts any pool pairing

**Problem**: Hook assumes currency0 is ETH, but doesn't enforce it

**Proposed Solution**:

```solidity
function beforeInitialize(
    address,
    PoolKey calldata key,
    uint160
) external override onlyPoolManager returns (bytes4) {
    // Validate currency0 is ETH
    require(
        Currency.unwrap(key.currency0) == nativeToken,
        "Currency0 must be native token"
    );

    // Validate currency1 is not ETH
    require(
        Currency.unwrap(key.currency1) != nativeToken,
        "Currency1 cannot be native token"
    );

    return IHooks.beforeInitialize.selector;
}
```

**Benefits**:
- Prevents misuse
- Clearer error messages
- Safer deployment

**Implementation Effort**: Low (1-2 hours)

---

### 2. Configurable Fee Percentage

**Current**: Hardcoded 1% fee (100 BPS)

**Problem**: One size doesn't fit all tokens

**Proposed Solution**:

```solidity
// Per-pool fee configuration
mapping(PoolId => uint256) public poolFeeBPS;

// Set during initialization
function beforeInitialize(
    address,
    PoolKey calldata key,
    uint160,
    bytes calldata hookData
) external override onlyPoolManager returns (bytes4) {
    // Decode fee from hookData
    uint256 feeBPS = abi.decode(hookData, (uint256));

    // Validate range (0.1% - 2%)
    require(feeBPS >= 10 && feeBPS <= 200, "Fee out of range");

    poolFeeBPS[key.toId()] = feeBPS;

    return IHooks.beforeInitialize.selector;
}
```

**Use Cases**:
- Stable pools: Lower fees (0.1-0.3%)
- Volatile pools: Higher fees (1-2%)
- Blue chip tokens: Medium fees (0.5%)

**Implementation Effort**: Medium (2-4 hours)

---

### 3. Fee Distribution Threshold Configuration

**Current**: Hardcoded 0.0001 ETH threshold

**Problem**: Optimal threshold depends on gas prices and pool activity

**Proposed Solution**:

```solidity
// Adjustable threshold
uint256 public donateThreshold = 0.0001 ether;

// Admin function to adjust
function setDonateThreshold(uint256 newThreshold) external onlyOwner {
    require(newThreshold >= 0.00001 ether, "Too low");
    require(newThreshold <= 0.01 ether, "Too high");

    donateThreshold = newThreshold;
    emit ThresholdUpdated(newThreshold);
}
```

**Benefits**:
- Adapt to changing gas prices
- Optimize for pool activity
- More frequent distributions when economical

**Implementation Effort**: Low (1 hour)

---

### 4. Emergency Pause Mechanism

**Current**: No way to halt hook in emergency

**Problem**: If bug discovered, need way to stop operations

**Proposed Solution**:

```solidity
bool public paused;

modifier whenNotPaused() {
    require(!paused, "Hook is paused");
    _;
}

function pause() external onlyOwner {
    paused = true;
    emit Paused(msg.sender);
}

function unpause() external onlyOwner {
    paused = false;
    emit Unpaused(msg.sender);
}

function beforeSwap(...) external override onlyPoolManager whenNotPaused returns (...) {
    // Hook logic...
}

function afterSwap(...) external override onlyPoolManager whenNotPaused returns (...) {
    // Hook logic...
}
```

**Emergency Procedure**:
1. Bug discovered
2. Owner calls pause()
3. All swaps proceed normally (hook just returns)
4. Fix bug in new version
5. Deploy new hook
6. Migrate pools

**Implementation Effort**: Low (2 hours)

---

### 5. Better Event Logging

**Current**: Basic events

**Proposed Enhancement**:

```solidity
event InternalSwapExecuted(
    PoolId indexed poolId,
    address indexed user,
    uint256 tokenIn,
    uint256 ethOut,
    uint256 amountToSwapBefore,    // NEW
    uint256 amountToSwapAfter,     // NEW
    uint256 priceX96               // NEW
);

event FeesDistributed(
    PoolId indexed poolId,
    uint256 amount0,
    uint256 recipientCount,        // NEW: number of LPs
    uint256 averageShare          // NEW: avg amount per LP
);

event FeeCaptureDetails(          // NEW EVENT
    PoolId indexed poolId,
    address indexed user,
    bool zeroForOne,
    uint256 swapAmount,
    uint256 feeAmount,
    uint256 feeBPS
);
```

**Benefits**:
- Better analytics
- Easier debugging
- Rich data for frontends

**Implementation Effort**: Low (1-2 hours)

---

## Medium-Term Improvements (Month 2-3)

### 6. Concentrated Liquidity for Internal Reserves

**Current**: Flat TOKEN reserves

**Problem**: Reserves don't earn yield

**Proposed Solution**: Use Uniswap V4 positions

```solidity
// Instead of flat reserves
mapping(PoolId => ClaimableFees) internal _poolFees;

// Use LP positions
mapping(PoolId => uint256) internal positionTokenId;

function _depositFeesAsLiquidity(
    PoolKey calldata key,
    uint256 tokenAmount
) internal {
    // Calculate current price ticks
    (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());
    int24 currentTick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

    // Create tight range around current price
    int24 tickLower = currentTick - 10;
    int24 tickUpper = currentTick + 10;

    // Add liquidity
    poolManager.modifyLiquidity(
        key,
        IPoolManager.ModifyLiquidityParams({
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidityDelta: calculateLiquidityDelta(tokenAmount),
            salt: bytes32(0)
        }),
        ""
    );
}
```

**Benefits**:
- Internal reserves earn fees from AMM
- More capital efficient
- Better alignment with pool LPs

**Challenges**:
- More complex logic
- Need to handle position management
- Rebalancing required

**Implementation Effort**: High (1-2 weeks)

---

### 7. Multi-Tier Fee Structure

**Current**: Single 1% fee for all swaps

**Proposed**: Volume-based fees

```solidity
struct FeeTier {
    uint256 threshold;  // Swap size threshold
    uint256 feeBPS;     // Fee for this tier
}

mapping(PoolId => FeeTier[]) public feeTiers;

function calculateFee(
    PoolId poolId,
    uint256 swapAmount
) internal view returns (uint256) {
    FeeTier[] memory tiers = feeTiers[poolId];

    for (uint256 i = tiers.length; i > 0; i--) {
        if (swapAmount >= tiers[i-1].threshold) {
            return (swapAmount * tiers[i-1].feeBPS) / BPS_DENOMINATOR;
        }
    }

    // Default fee
    return (swapAmount * FEE_BPS) / BPS_DENOMINATOR;
}

// Example setup:
// 0-1 ETH: 1.0% fee
// 1-10 ETH: 0.5% fee
// 10+ ETH: 0.25% fee
```

**Benefits**:
- Incentivize larger trades
- More competitive for whales
- Progressive fee structure

**Implementation Effort**: Medium (3-5 days)

---

### 8. Whitelist for Fee Exemptions

**Current**: Everyone pays fees

**Proposed**: Exempt certain addresses

```solidity
mapping(address => bool) public feeExempt;

function setFeeExempt(address user, bool exempt) external onlyOwner {
    feeExempt[user] = exempt;
    emit FeeExemptionUpdated(user, exempt);
}

function afterSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata
) external override onlyPoolManager returns (bytes4, int128) {
    // Check exemption
    if (feeExempt[sender]) {
        return (IHooks.afterSwap.selector, 0);  // No fee
    }

    // Normal fee logic...
}
```

**Use Cases**:
- Protocol-owned liquidity
- Partnerships
- Market makers
- Migration incentives

**Implementation Effort**: Low (2-3 hours)

---

### 9. Dynamic Fee Adjustment Based on Volatility

**Current**: Static fee

**Proposed**: Adjust fee based on market conditions

```solidity
struct VolatilityTracker {
    uint256 lastPrice;
    uint256 lastUpdateTime;
    uint256 volatilityIndex;  // 0-1000, higher = more volatile
}

mapping(PoolId => VolatilityTracker) internal volatility;

function updateVolatility(PoolId poolId) internal {
    VolatilityTracker storage tracker = volatility[poolId];
    (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);

    if (block.timestamp - tracker.lastUpdateTime >= 1 hours) {
        // Calculate price change
        uint256 priceChange = abs(sqrtPriceX96 - tracker.lastPrice);
        uint256 percentChange = (priceChange * 1000) / tracker.lastPrice;

        // Update volatility index (EMA)
        tracker.volatilityIndex =
            (tracker.volatilityIndex * 9 + percentChange) / 10;

        tracker.lastPrice = sqrtPriceX96;
        tracker.lastUpdateTime = block.timestamp;
    }
}

function calculateDynamicFee(PoolId poolId) internal view returns (uint256) {
    uint256 vol = volatility[poolId].volatilityIndex;

    // Base fee + volatility premium
    // Low volatility (0-50): 0.5% fee
    // Medium volatility (50-200): 1.0% fee
    // High volatility (200+): 1.5% fee

    if (vol <= 50) return 50;   // 0.5%
    if (vol <= 200) return 100;  // 1.0%
    return 150;                  // 1.5%
}
```

**Benefits**:
- Protects against adverse selection
- Fair pricing for market conditions
- Auto-adjusts to risk

**Challenges**:
- Oracle manipulation risk
- Gas costs for tracking
- Complexity

**Implementation Effort**: High (1-2 weeks)

---

## Long-Term Improvements (Month 4-6)

### 10. Governance System

**Current**: Owner-controlled

**Proposed**: Decentralized governance

```solidity
interface IGovernance {
    function propose(
        address target,
        bytes calldata data,
        string calldata description
    ) external returns (uint256 proposalId);

    function vote(uint256 proposalId, bool support) external;

    function execute(uint256 proposalId) external;
}

contract GovernedInternalSwapPool is InternalSwapPool {
    IGovernance public governance;

    modifier onlyGovernance() {
        require(msg.sender == address(governance), "Only governance");
        _;
    }

    function setDonateThreshold(uint256 newThreshold)
        external
        override
        onlyGovernance  // Changed from onlyOwner
    {
        // ...
    }

    // All admin functions protected by governance
}
```

**Governance Powers**:
- Adjust fee percentages
- Set fee exemptions
- Emergency pause
- Upgrade contracts
- Parameter tuning

**Implementation Effort**: Very High (3-4 weeks)

---

### 11. Cross-Pool Fee Sharing

**Current**: Each pool independent

**Proposed**: Share fees across multiple pools

```solidity
contract FeeDistributor {
    mapping(PoolId => uint256) public poolWeights;
    uint256 public totalWeight;

    function distributeCrossPoolFees() external {
        uint256 totalFees = address(this).balance;

        for (uint256 i = 0; i < activePools.length; i++) {
            PoolId poolId = activePools[i];
            uint256 weight = poolWeights[poolId];

            uint256 poolShare = (totalFees * weight) / totalWeight;

            // Distribute to pool's LPs
            poolManager.donate(pools[poolId], poolShare, 0, "");
        }
    }
}
```

**Use Cases**:
- Protocol-wide fee sharing
- Incentivize liquidity in new pools
- Bootstrap smaller pools
- DAO treasury management

**Implementation Effort**: High (2-3 weeks)

---

### 12. Integration with External Orderbooks

**Current**: Only internal reserves

**Proposed**: Fill from external sources

```solidity
interface IOrderbook {
    function getQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function executeOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut);
}

function _fillFromExternalOrderbook(
    PoolKey calldata key,
    uint256 tokenIn
) internal returns (uint256 ethOut) {
    // Try external orderbook first
    ethOut = orderbook.executeOrder(
        Currency.unwrap(key.currency1),
        Currency.unwrap(key.currency0),
        tokenIn,
        calculateMinOut(tokenIn)
    );

    // If not enough, fill remainder from internal
    if (ethOut < requiredEthOut) {
        uint256 remainingToken = calculateRemainingToken(ethOut);
        ethOut += _fillFromInternal(remainingToken);
    }
}
```

**Benefits**:
- Deeper liquidity
- Better prices
- Cross-DEX aggregation
- Reduced slippage

**Challenges**:
- External calls (security risk)
- Gas costs
- Complexity
- Oracle requirements

**Implementation Effort**: Very High (4-6 weeks)

---

### 13. NFT-Gated Fees

**Current**: Same fees for everyone

**Proposed**: NFT holders get discounts

```solidity
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

IERC721 public loyaltyNFT;

mapping(uint256 => uint256) public tierDiscounts;
// Tier 1 (1 NFT): 10% discount
// Tier 2 (5 NFTs): 25% discount
// Tier 3 (10 NFTs): 50% discount

function calculateFeeWithDiscount(
    address user,
    uint256 baseSwapFee
) internal view returns (uint256) {
    uint256 nftCount = loyaltyNFT.balanceOf(user);

    if (nftCount >= 10) {
        return baseSwapFee / 2;  // 50% off
    } else if (nftCount >= 5) {
        return (baseSwapFee * 75) / 100;  // 25% off
    } else if (nftCount >= 1) {
        return (baseSwapFee * 90) / 100;  // 10% off
    }

    return baseSwapFee;  // No discount
}
```

**Benefits**:
- Community engagement
- Loyalty rewards
- Additional revenue stream (NFT sales)
- Marketing appeal

**Implementation Effort**: Medium (1 week)

---

### 14. Time-Weighted Fee Distribution

**Current**: Instant distribution to current LPs

**Proposed**: Reward long-term LPs more

```solidity
struct LPInfo {
    uint256 liquidityAmount;
    uint256 depositTime;
    uint256 lastClaimTime;
}

mapping(address => mapping(PoolId => LPInfo)) public lpInfo;

function calculateLPShare(
    address lp,
    PoolId poolId,
    uint256 totalFees
) internal view returns (uint256) {
    LPInfo memory info = lpInfo[lp][poolId];

    // Base share (proportional to liquidity)
    uint256 baseShare = (totalFees * info.liquidityAmount) / totalLiquidity;

    // Time multiplier (1x to 2x based on hold duration)
    uint256 holdDuration = block.timestamp - info.depositTime;
    uint256 multiplier = 100 + min(100, holdDuration / 1 days);  // Up to 2x

    return (baseShare * multiplier) / 100;
}
```

**Benefits**:
- Incentivize long-term liquidity
- Reduce mercenary capital
- More stable TVL
- Better for token price

**Implementation Effort**: High (2-3 weeks)

---

## Research Directions

### 15. MEV Protection

**Question**: Can hooks be sandwiched?

**Research Areas**:
- Flashloan attacks on internal reserves
- Price manipulation vectors
- Front-running internal fills

**Potential Solutions**:
- Private mempool integration
- Commit-reveal schemes
- MEV rebates to users

---

### 16. Layer 2 Optimization

**Question**: How to optimize for L2s?

**Research Areas**:
- Blob data for fee tracking
- Cross-chain fee distribution
- Optimistic internal fills

**Potential Solutions**:
- Off-chain fee calculation
- Merkle proofs for distributions
- Aggregated settlements

---

### 17. Alternative Fee Conversion Strategies

**Current**: Convert TOKEN → ETH

**Alternative Ideas**:

**Option A**: Convert to stablecoin
- More stable value
- Easier accounting
- But: requires stablecoin liquidity

**Option B**: Convert to protocol token
- Aligns incentives with protocol
- Creates buy pressure
- But: might not want to expose to token

**Option C**: Let LPs choose
- Ultimate flexibility
- Personalized preferences
- But: more complexity

---

## Implementation Roadmap

### Phase 1: Core Improvements (Month 1)
```
Week 1-2:
├─ Pool validation
├─ Configurable fees
└─ Better events

Week 3-4:
├─ Emergency pause
├─ Fee threshold config
└─ Comprehensive testing
```

### Phase 2: Advanced Features (Month 2-3)
```
Week 5-8:
├─ Concentrated liquidity integration
├─ Multi-tier fees
└─ Whitelist system

Week 9-12:
├─ Dynamic fees
├─ NFT-gated fees
└─ Security audit
```

### Phase 3: Governance & Scale (Month 4-6)
```
Week 13-16:
├─ Governance system
├─ Cross-pool sharing
└─ Time-weighted distribution

Week 17-24:
├─ External orderbook integration
├─ L2 optimization
└─ MEV protection
```

---

## Prioritization Matrix

### High Impact, Low Effort (Do First)
1. ✅ Pool validation
2. ✅ Configurable fees
3. ✅ Emergency pause
4. ✅ Better events

### High Impact, High Effort (Do Second)
5. Concentrated liquidity
6. Dynamic fees
7. Governance system

### Medium Impact, Low Effort (Do Third)
8. Fee exemptions
9. NFT-gated fees
10. Threshold config

### Low Priority (Do Later)
11. Cross-pool sharing
12. External orderbook
13. L2 optimization

---

## Community Feedback Integration

### Where to Gather Feedback

1. **Twitter**: Share hook and ask for feature requests
2. **Discord**: Uniswap governance channels
3. **Forum**: Detailed proposals and discussions
4. **GitHub**: Issues and pull requests
5. **Direct**: Talk to projects planning to use it

### Questions to Ask

1. What fee percentage would you prefer?
2. Should fees be adjustable per-pool?
3. Is emergency pause important to you?
4. Would you pay more for MEV protection?
5. Do you want governance or trust core team?

---

## Conclusion

The InternalSwapPool hook has significant room for growth. The roadmap balances:
- Quick wins (pool validation, events)
- High-impact features (concentrated liquidity, governance)
- Long-term vision (cross-DEX, L2, MEV)

**Next Immediate Steps**:
1. Deploy current version to testnet
2. Gather community feedback
3. Implement Phase 1 improvements
4. Security audit before mainnet

The hook is production-ready now, but these improvements will make it even more powerful and flexible for real-world usage.

---

[← Back to Testing Strategy](./06-testing-strategy.md) | [Back to Main README →](./README.md)
