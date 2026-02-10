# NFPool SDK Integration Guide

Complete examples for integrating NFPool into applications.

---

## SDK Installation

```bash
npm install @nfpool/sdk
# or
yarn add @nfpool/sdk
```

---

## Basic Pool Deployment

### Collateralized Pool

```typescript
import { NFPool } from '@nfpool/sdk';

const collateralPool = await NFPool.create({
  chain: 'base',
  mode: 'COLLATERALIZED',
  nftCollection: '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D', // BAYC
  backingRatio: 1.25, // 125% over-collateralized
  feeModel: 'dynamic',
  vault: {
    minDeposit: 1, // Minimum 1 NFT
    redemptionFee: 0.01 // 1% fee
  }
});

await collateralPool.deploy();
console.log('Pool deployed at:', collateralPool.address);
```

### Speculative Pool

```typescript
const speculativePool = await NFPool.create({
  chain: 'base',
  mode: 'SPECULATIVE',
  nftCollection: '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D', // BAYC
  tokenName: 'BAYC Exposure',
  tokenSymbol: 'BAYC',
  strategy: {
    enabled: true,
    buyNFTsOnSurplus: true,
    relistMultiplier: 1.2,
    burnOnSale: true,
    maxGasPerSwap: 50_000
  }
});

await speculativePool.deploy();
```

### Hybrid Pool

```typescript
const hybridPool = await NFPool.create({
  chain: 'base',
  mode: 'HYBRID',
  nftCollection: '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D', // BAYC
  backingRatio: 1.5, // 150% over-collateralized (allows speculation)
  vault: { minDeposit: 1, redemptionFee: 0.01 },
  strategy: { enabled: true, buyNFTsOnSurplus: true, burnOnSale: true }
});

await hybridPool.deploy();
```

---

## Analytics

```typescript
const stats = await pool.analytics();

console.log(stats);
/*
{
  mode: 'HYBRID',
  backingRatio: 1.52,
  totalNFTs: 45,
  totalSupply: 39.2,
  floorPrice: 18.5,
  weeklyVolume: 125.3,
  feesAccumulated: 2.5,
  nftsBought: 3,
  tokensBurned: 1.2
}
*/
```

---

## User Interactions

### Deposit NFT (Collateralized Mode)

```typescript
await nfpool.deposit({
  nftId: 1234,
  onMint: (tokens) => {
    console.log(`Minted ${tokens} NFT-BAYC tokens`);
  }
});
```

### Swap Tokens

```typescript
// Buy speculative tokens
await nfpool.swap({
  from: 'USDC',
  to: 'BAYC',
  amount: 1000 // Buy $1000 worth
});

// Sell for USDC
await nfpool.swap({
  from: 'BAYC',
  to: 'USDC',
  amount: 0.5 // Sell 0.5 tokens
});
```

### Redeem NFT (Collateralized Mode)

```typescript
await nfpool.redeem({
  amount: 1.0, // Burn 1 token
  preferredNFT: 1234 // Optional: get specific NFT back
});
```

### Check Pool Mode

```typescript
const mode = await nfpool.getMode();
// Returns: 'COLLATERALIZED' | 'SPECULATIVE' | 'HYBRID'
```

---

## Frontend Integration

### React Hook Example

```typescript
import { useNFPool } from '@nfpool/react';

function NFPoolInterface() {
  const { pool, deposit, swap, redeem, stats } = useNFPool({
    poolAddress: '0x...',
    chain: 'base'
  });

  const handleDeposit = async (nftId: number) => {
    const tx = await deposit(nftId);
    await tx.wait();
    console.log('NFT deposited');
  };

  return (
    <div>
      <h2>Pool Stats</h2>
      <p>Backing Ratio: {stats.backingRatio}x</p>
      <p>Total NFTs: {stats.totalNFTs}</p>
      <p>Mode: {stats.mode}</p>

      <button onClick={() => handleDeposit(1234)}>
        Deposit NFT #1234
      </button>
    </div>
  );
}
```

---

## Advanced Usage

### Custom Oracle Integration

```typescript
const pool = await NFPool.create({
  // ... other config
  oracle: {
    type: 'custom',
    address: '0x...', // Custom oracle contract
    updateInterval: 3600, // Update every hour
    fallback: 'chainlink' // Fallback to Chainlink if custom fails
  }
});
```

### Event Monitoring

```typescript
pool.on('NFTDeposited', (user, tokenId, value) => {
  console.log(`${user} deposited NFT #${tokenId} worth ${value}`);
});

pool.on('StrategyExecuted', (nftId, price) => {
  console.log(`Strategy bought NFT #${nftId} for ${price}`);
});

pool.on('TokensBurned', (amount, value) => {
  console.log(`Burned ${amount} tokens worth ${value}`);
});
```

### Governance Operations

```typescript
// Propose mode transition
await pool.governance.propose({
  action: 'TRANSITION_TO_HYBRID',
  params: {
    newBackingRatio: 1.5,
    enableStrategy: true
  },
  description: 'Enable hybrid mode for growth'
});

// Vote on proposal
await pool.governance.vote(proposalId, true);

// Execute after timelock
await pool.governance.execute(proposalId);
```

---

## Error Handling

```typescript
try {
  await pool.deposit(nftId);
} catch (error) {
  if (error.code === 'INSUFFICIENT_BACKING') {
    console.error('Pool backing ratio too low');
  } else if (error.code === 'INVALID_NFT') {
    console.error('NFT not from correct collection');
  } else if (error.code === 'MINT_CAP_EXCEEDED') {
    console.error('Pool has reached maximum supply');
  }
}
```

---

## Testing

```typescript
import { NFPoolTestKit } from '@nfpool/test-utils';

describe('NFPool Integration', () => {
  let testKit: NFPoolTestKit;

  beforeEach(async () => {
    testKit = await NFPoolTestKit.setup({
      mode: 'COLLATERALIZED',
      mockNFTs: 10
    });
  });

  it('should deposit NFT and mint tokens', async () => {
    const tx = await testKit.pool.deposit(1);
    await tx.wait();

    const balance = await testKit.token.balanceOf(testKit.user.address);
    expect(balance).to.be.gt(0);
  });

  it('should enforce backing ratio', async () => {
    // Attempt to mint without sufficient backing
    await expect(
      testKit.pool.mintWithoutDeposit(100)
    ).to.be.revertedWith('InsufficientBacking');
  });
});
```

---

## Performance Optimization

### Batch Operations

```typescript
// Batch multiple deposits
await pool.batchDeposit([1234, 5678, 9012]);

// Batch swaps with multicall
await pool.multicall([
  pool.interface.encodeFunctionData('swap', [params1]),
  pool.interface.encodeFunctionData('swap', [params2])
]);
```

### Gas Estimation

```typescript
const gasEstimate = await pool.estimateGas.deposit(nftId);
console.log(`Estimated gas: ${gasEstimate.toString()}`);

// Add buffer
const gasLimit = gasEstimate.mul(120).div(100); // 20% buffer
await pool.deposit(nftId, { gasLimit });
```

---

## Security Best Practices

### Input Validation

```typescript
// Validate NFT ownership before deposit
const owner = await nftContract.ownerOf(tokenId);
if (owner !== userAddress) {
  throw new Error('User does not own this NFT');
}

// Verify pool health before large operations
const health = await pool.getHealth();
if (health < MINIMUM_HEALTH_THRESHOLD) {
  console.warn('Pool health is low, proceed with caution');
}
```

### Slippage Protection

```typescript
await pool.swap({
  from: 'BAYC',
  to: 'USDC',
  amount: 1.0,
  minOutput: 0.95, // Accept up to 5% slippage
  deadline: Date.now() + 60000 // 1 minute deadline
});
```

---

## Migration Guide

### Upgrading from v1 to v2

```typescript
// v1 (deprecated)
const pool = new NFPool(config);
await pool.initialize();

// v2 (current)
const pool = await NFPool.create(config);
await pool.deploy();
```

### Breaking Changes

- `initialize()` replaced with `deploy()`
- `getMetrics()` replaced with `analytics()`
- Fee structure changed from fixed to dynamic by default
- Oracle integration now required for collateralized pools
