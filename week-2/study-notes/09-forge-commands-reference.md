# Forge Commands Reference Guide

**Author**: Allan Robinson
**Date**: January 29, 2026
**Context**: Essential commands for hook development

---

## Testing Commands

### Basic Test Execution

```bash
# Run all tests
forge test

# Run with logs
forge test -vv

# Run specific test
forge test --match-test testSwapAwardsPoints

# Run specific contract
forge test --match-contract PointsHookTest
```

### Verbosity Levels

```bash
forge test      # Silent - only pass/fail
forge test -v   # Show test names
forge test -vv  # Show console.log output
forge test -vvv # Show stack traces on failure
forge test -vvvv # Show setup traces
forge test -vvvvv # Show ALL internal calls
```

**My usage**:
- `-vv` during development (see my logs)
- `-vvvv` when debugging failures
- `-vvvvv` rarely (too verbose)

### Gas Reporting

```bash
# Generate gas report
forge test --gas-report

# Save report to file
forge test --gas-report > gas-report.txt

# Show gas for specific test
forge test --match-test testSwap --gas-report
```

**Output example**:
```
| Function        | Calls | Mean  | Max   |
|-----------------|-------|-------|-------|
| _afterSwap      | 10    | 45231 | 47891 |
| _assignPoints   | 10    | 23450 | 23450 |
```

### Coverage Analysis

```bash
# Generate coverage report
forge coverage

# Summary only
forge coverage --report summary

# Detailed per-file
forge coverage --report lcov

# Debug coverage (see uncovered lines)
forge coverage --report debug
```

**Target**: >90% coverage on production code

---

## Building & Compilation

### Standard Build

```bash
# Build all contracts
forge build

# Clean and rebuild
forge clean && forge build

# Build with specific optimizer runs
forge build --optimizer-runs 1000000
```

### Size Optimization

```bash
# Check contract sizes
forge build --sizes

# Optimize for size
forge build --optimizer-runs 1 --via-ir
```

**Size limits**:
- Mainnet: 24KB per contract
- If exceeding: Split contracts or optimize further

---

## Deployment Commands

### Local Deployment (Anvil)

```bash
# Start local node
anvil

# Deploy to local node
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Testnet Deployment

```bash
# Sepolia
forge script script/Deploy.s.sol \
    --rpc-url $SEPOLIA_RPC \
    --broadcast \
    --verify

# With specific gas price
forge script script/Deploy.s.sol \
    --rpc-url $SEPOLIA_RPC \
    --gas-price 20gwei \
    --broadcast
```

### Verification

```bash
# Verify on Etherscan
forge verify-contract <address> PointsHook \
    --chain sepolia \
    --etherscan-api-key $ETHERSCAN_KEY

# Verify with constructor args
forge verify-contract <address> PointsHook \
    --chain sepolia \
    --constructor-args $(cast abi-encode "constructor(address)" $POOL_MANAGER)
```

---

## Debugging Commands

### Trace Specific Transaction

```bash
# Trace a test
forge test --match-test testSwap -vvvvv

# Trace and show gas
forge test --match-test testSwap -vvvvv --gas-report
```

### Interactive Debugging

```bash
# Debug specific test
forge test --match-test testSwap --debug

# Opens TUI debugger:
# - Step through execution
# - View stack
# - Check storage
# - Inspect memory
```

**Keys in debugger**:
- `n`: Next step
- `s`: Step into function
- `o`: Step out of function
- `q`: Quit
- `h`: Help

---

## Utility Commands

### Cast (CLI Tool)

```bash
# Convert hex to decimal
cast --to-dec 0x64

