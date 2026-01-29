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

