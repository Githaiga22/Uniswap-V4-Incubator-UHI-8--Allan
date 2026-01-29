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

# Convert decimal to hex
cast --to-hex 100

# ABI encode
cast abi-encode "transfer(address,uint256)" 0x... 100

# Calculate function selector
cast sig "afterSwap(address,(...),bytes)"

# Get storage at slot
cast storage <contract> <slot> --rpc-url $RPC

# Call view function
cast call <contract> "getPoints(address,bytes32)" $USER $POOL_ID --rpc-url $RPC
```

### Snapshot (Gas Comparison)

```bash
# Create baseline
forge snapshot

# Compare after changes
forge snapshot --diff

# Save to file
forge snapshot --snap baseline.snap
```

**Usage pattern**:
1. Make code change
2. Run `forge snapshot --diff`
3. Check if gas increased/decreased
4. Keep if improved, revert if worse

---

## Configuration Commands

### View Current Config

```bash
# Show remappings
forge remappings

# Show config
forge config

# List installed libraries
forge tree
```

### Install Dependencies

```bash
# Install from GitHub
forge install openzeppelin/openzeppelin-contracts

# Install specific version
forge install openzeppelin/openzeppelin-contracts@v4.9.0

# Update dependencies
forge update

# Remove dependency
forge remove openzeppelin-contracts
```

---

## Fuzz Testing

### Basic Fuzzing

```bash
# Run fuzz tests (default: 256 runs)
forge test --match-test testFuzz

# More thorough (10,000 runs)
forge test --match-test testFuzz --fuzz-runs 10000

# Deeper (100,000 runs - slow!)
forge test --match-test testFuzz --fuzz-runs 100000
```

**Example fuzz test**:
```solidity
function testFuzz_PointsAlwaysPositive(uint8 swapCount) public {
    for (uint256 i = 0; i < swapCount; i++) {
        swap(...);
    }
    uint256 points = hook.getPoints(alice, poolId);
    assertGe(points, 0);
}
```

---

## Fork Testing

### Run Tests on Forked Mainnet

```bash
# Fork from latest block
forge test --fork-url $MAINNET_RPC

# Fork from specific block
forge test --fork-url $MAINNET_RPC --fork-block-number 19000000

# Run specific test on fork
forge test --match-test testIntegration --fork-url $MAINNET_RPC -vvv
```

**Environment setup**:
```bash
export MAINNET_RPC="https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"
export SEPOLIA_RPC="https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"
```

---

## Continuous Integration

### CI-Friendly Commands

```bash
# Run all tests (no compilation cache)
forge test --no-match-test "testFuzz_*" --force

# Generate coverage for CI
forge coverage --report lcov

# Check gas limits
forge test --gas-limit 30000000

# Fail on warnings
forge build --deny-warnings
```

**.github/workflows/test.yml**:
```yaml
- name: Run tests
  run: forge test --gas-report

- name: Check coverage
  run: forge coverage --report summary

- name: Check gas snapshots
  run: forge snapshot --check
```

---

## Performance Profiling

### Flamegraph Generation

```bash
# Generate flamegraph for test
forge test --match-test testSwap --flamegraph

# Output: flamegraph-<test>.svg
# Open in browser to visualize gas usage
```

**Interpreting flamegraphs**:
- Width = gas consumed
- Color = call depth
- Hover for details

---

## My Daily Workflow

### Morning (Start Development)

```bash
# 1. Update dependencies
forge update

# 2. Clean build
forge clean && forge build

# 3. Run tests
forge test -vv

# 4. Check coverage
forge coverage --report summary
```

### During Development

```bash
# Run specific test repeatedly
forge test --match-test testNewFeature -vv

# Check gas impact
forge snapshot --diff

# Debug failures
