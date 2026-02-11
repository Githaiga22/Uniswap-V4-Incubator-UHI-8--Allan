# InternalSwapPool Deployment Guide

This guide walks through deploying the InternalSwapPool hook to Base Sepolia testnet.

---

## Prerequisites

1. **Foundry installed**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Funded wallet on Base Sepolia**
   - Get test ETH from [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-goerli-faucet)
   - Minimum 0.01 ETH recommended for deployment + gas

3. **Basescan API Key** (for contract verification)
   - Sign up at [Basescan](https://basescan.org/)
   - Create API key in your account dashboard

---

## Environment Setup

1. **Copy environment template**
   ```bash
   cp .env.example .env
   ```

2. **Fill in .env file**
   ```bash
   # Private key (WITHOUT 0x prefix)
   PRIVATE_KEY=your_private_key_here

   # Base Sepolia RPC
   BASE_SEPOLIA_RPC_URL=https://sepolia.base.org

   # Basescan API Key
   BASESCAN_API_KEY=your_api_key_here
   ```

3. **Load environment variables**
   ```bash
   source .env
   ```

---

## Deployment Steps

### Step 1: Run Tests

Before deploying, ensure all tests pass:

```bash
forge test -vvv
```

Expected output:
```
Running 11 tests for test/InternalSwapPool.t.sol:InternalSwapPoolTest
[PASS] test_BeforeSwapDelta_InternalPool() (gas: 344567)
[PASS] test_CreatePoolWithHook() (gas: 234123)
[PASS] test_DistributeFees() (gas: 189456)
...
Test result: ok. 11 passed; 0 failed
```

### Step 2: Compile Contracts

```bash
forge build
```

### Step 3: Deploy to Base Sepolia

```bash
forge script script/Deploy.s.sol \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    -vvvv
```

**What this does**:
- Deploys InternalSwapPool hook
- Automatically verifies contract on Basescan
- Outputs hook address and deployment info

### Step 4: Verify Deployment

After deployment, you should see:

```
=== Deployment Complete ===
Hook Address: 0x...
PoolManager: 0xf242cE588b030d0895c51C0730F2368680f80644

Next steps:
1. Verify contract on Basescan
2. Create pool with this hook
3. Add liquidity to pool
4. Test swap functionality
```

**Verify on Basescan**:
1. Go to [Base Sepolia Explorer](https://sepolia.basescan.org/)
2. Search for your hook address
3. Confirm contract is verified (green checkmark)
4. Review contract code and ABI

---

## Post-Deployment Configuration

### Create a Pool with the Hook

After deployment, you need to create a Uniswap v4 pool that uses your hook:

```solidity
// Example: Create USDC/ETH pool with InternalSwapPool hook
PoolKey memory key = PoolKey({
    currency0: Currency.wrap(address(WETH)),
    currency1: Currency.wrap(address(USDC)),
    fee: 3000, // 0.3%
    tickSpacing: 60,
    hooks: IHooks(hookAddress) // Your deployed hook
});

// Initialize pool
poolManager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);
```

### Add Initial Liquidity

```solidity
// Add liquidity to enable swaps
positionManager.mint(
    key,
    tickLower,
    tickUpper,
    liquidityAmount,
    amount0Max,
    amount1Max,
    recipient,
    deadline,
    hookData
);
```

---

## Troubleshooting

### Issue: "Hook address flags do not match required flags"

**Problem**: The deployed hook address doesn't have the correct flags in its address.

**Solution**: Use CREATE2 deployment with a specific salt to generate an address with correct flags.

```solidity
// Find salt that produces address with correct flags
bytes32 salt = findSalt(bytecode, FLAGS);

// Deploy with CREATE2
address hook = address(new InternalSwapPool{salt: salt}(poolManager));
```

### Issue: "Insufficient funds for gas"

**Problem**: Wallet doesn't have enough ETH for deployment.

**Solution**: Get more test ETH from Base Sepolia faucet.

### Issue: "Contract verification failed"

**Problem**: Basescan couldn't verify the contract automatically.

**Solution**: Manually verify on Basescan:
1. Go to your contract on Basescan
2. Click "Verify and Publish"
3. Select compiler version (0.8.26)
4. Paste flattened source code:
   ```bash
   forge flatten src/InternalSwapPool.sol > flattened.sol
   ```
5. Submit for verification

---

## Deployment Costs

Estimated gas costs on Base Sepolia:

| Operation | Gas Cost | ETH Cost (at 1 gwei) |
|-----------|----------|---------------------|
| Deploy Hook | ~2,500,000 | 0.0025 ETH |
| Verify Contract | Free | 0 ETH |
| **Total** | **~2,500,000** | **~0.0025 ETH** |

Note: Actual costs may vary based on network congestion.

---

## Verifying Deployment Success

### 1. Check Contract on Basescan

Visit: `https://sepolia.basescan.org/address/<hook-address>`

Verify:
- [x] Contract is verified (green checkmark)
- [x] Source code is visible
- [x] ABI is accessible
- [x] Constructor args are correct

### 2. Test Hook Functions

```bash
# Read hook state
cast call <hook-address> "poolManager()(address)" \
    --rpc-url $BASE_SEPOLIA_RPC_URL

# Expected: 0xf242cE588b030d0895c51C0730F2368680f80644
```

### 3. Check Hook Permissions

```bash
cast call <hook-address> "getHookPermissions()(tuple)" \
    --rpc-url $BASE_SEPOLIA_RPC_URL
```

Expected permissions:
- beforeSwap: true
- afterSwap: true
- beforeSwapReturnsDelta: true

---

## Next Steps After Deployment

1. **Create Test Pool**
   - Deploy test ERC20 tokens (if needed)
   - Initialize pool with hook
   - Add liquidity

2. **Test Functionality**
   - Execute test swaps
   - Verify internal swap pool behavior
   - Check fee distribution

3. **Monitor Performance**
   - Track gas costs
   - Monitor hook executions
   - Analyze internal swap efficiency

4. **Documentation**
   - Update README with deployed addresses
   - Document pool creation steps
   - Share deployment info with team

---

## Important Addresses (Base Sepolia)

| Contract | Address |
|----------|---------|
| PoolManager | `0xf242cE588b030d0895c51C0730F2368680f80644` |
| InternalSwapPool Hook | `<YOUR_DEPLOYED_ADDRESS>` |

---

## Additional Resources

- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-goerli-faucet)
- [Uniswap v4 Docs](https://docs.uniswap.org/contracts/v4)
- [Foundry Book](https://book.getfoundry.sh/)

---

## Security Checklist

Before deploying to mainnet:

- [ ] All tests passing
- [ ] External audit completed
- [ ] Bug bounty program launched
- [ ] Emergency pause mechanism tested
- [ ] Gas costs optimized
- [ ] Documentation complete
- [ ] Team review completed

---

**Deployment Date**: February 2026
**Network**: Base Sepolia Testnet
**Status**: Ready for Deployment
