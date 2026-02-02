# Hook Security Assessment Worksheet

**Author**: Allan Robinson
**Date**: February 2, 2026
**Purpose**: Self-assessment tool for evaluating hook security

---

## Instructions

Use this worksheet to assess your hook's security profile using the Uniswap V4 Security Framework. Be honest in your scoring - overestimating safety can lead to vulnerabilities.

**Official Framework**: https://docs.uniswap.org/contracts/v4/security
**Risk Calculator**: https://docs.google.com/spreadsheets/d/1oZdKZh13UbqVp3HujAcv-2NKP-j7NQAELhB7kyWlLRE/edit

---

## Part 1: Basic Information

**Hook Name**: _______________________________

**Hook Address** (if deployed): _______________________________

**Primary Function**: _______________________________

**Expected TVL**: _______________________________

**Team Size**: _______________________________

---

## Part 2: Risk Dimension Scoring

Score each dimension honestly. Total score determines your risk tier.

### Dimension 1: Complexity (0-5 points)

**Question**: How complex is your hook's logic?

- [ ] **0 points**: Single hook function, minimal logic
- [ ] **1 point**: 1-2 hook functions, simple conditionals
- [ ] **2 points**: 2-3 hook functions, moderate branching
- [ ] **3 points**: 3-4 hook functions, complex state management
- [ ] **4 points**: 4+ hook functions, nested callbacks
- [ ] **5 points**: Multiple hooks interacting, high complexity

**Your Score**: _____ / 5

**Notes**: _______________________________

---

### Dimension 2: Custom Math (0-5 points)

**Question**: Does your hook implement custom mathematical operations?

- [ ] **0 points**: No custom math, only standard operations
- [ ] **1 point**: Simple arithmetic (add, subtract, multiply, divide)
- [ ] **2 points**: Percentages, basic fee calculations
- [ ] **3 points**: Custom pricing formulas, weighted averages
- [ ] **4 points**: Custom bonding curves, logarithms, exponents
- [ ] **5 points**: Novel AMM math, complex financial derivatives

**Your Score**: _____ / 5

**Custom Math Used**: _______________________________

---

### Dimension 3: External Dependencies (0-3 points)

**Question**: Does your hook rely on external contracts or data?

- [ ] **0 points**: No external dependencies
- [ ] **1 point**: One trusted dependency (e.g., Chainlink oracle)
- [ ] **2 points**: 2-3 dependencies or one untrusted dependency
- [ ] **3 points**: 3+ dependencies, cross-chain, or novel protocols

**Your Score**: _____ / 3

**Dependencies List**:
1. _______________________________
2. _______________________________
3. _______________________________

---

### Dimension 4: External Liquidity Exposure (0-3 points)

**Question**: Does your hook hold or manage liquidity in external protocols?

- [ ] **0 points**: No external liquidity
- [ ] **1 point**: Monitors external liquidity (read-only)
- [ ] **2 points**: Manages small amounts in external protocols
- [ ] **3 points**: Significant liquidity in external protocols

**Your Score**: _____ / 3

**External Protocols**: _______________________________

---

### Dimension 5: TVL Potential (0-5 points)

**Question**: What TVL do you expect your hook to manage?

- [ ] **0 points**: <$10K
- [ ] **1 point**: $10K - $100K
- [ ] **2 points**: $100K - $1M
- [ ] **3 points**: $1M - $10M
- [ ] **4 points**: $10M - $50M
- [ ] **5 points**: $50M+

**Your Score**: _____ / 5

**TVL Estimate**: $_______________________________

---

### Dimension 6: Team Maturity (0-3 points)

**Question**: What is your team's production experience?

- [ ] **0 points**: First production deployment
- [ ] **1 point**: 1-2 production deployments
- [ ] **2 points**: 3-5 production deployments
- [ ] **3 points**: 5+ production deployments

**Your Score**: _____ / 3

**Previous Deployments**: _______________________________

---

### Dimension 7: Upgradeability (0-3 points)

**Question**: Is your hook upgradeable?

- [ ] **0 points**: Fully immutable (no upgrades possible)
- [ ] **1 point**: Parameter updates only (no logic changes)
- [ ] **2 points**: Proxy with timelock/multisig
- [ ] **3 points**: Complex upgrade mechanism or admin control

**Your Score**: _____ / 3

**Upgrade Mechanism**: _______________________________

---

### Dimension 8: Autonomous Updates (0-3 points)

**Question**: Does your hook automatically adjust parameters?

- [ ] **0 points**: No autonomous behavior
- [ ] **1 point**: Simple on-chain triggers (e.g., time-based)
- [ ] **2 points**: Oracle-driven adjustments
- [ ] **3 points**: Complex autonomous logic (AI, ML, multi-factor)

**Your Score**: _____ / 3

**Autonomous Features**: _______________________________

---

### Dimension 9: Price Impact (0-3 points)

**Question**: Does your hook affect swap prices or routing?

- [ ] **0 points**: No price impact
- [ ] **1 point**: Informational only (doesn't change execution)
- [ ] **2 points**: Modifies fees or affects routing decisions
- [ ] **3 points**: Direct price manipulation or significant routing changes

**Your Score**: _____ / 3

**Price Impact Mechanism**: _______________________________

---

## Part 3: Risk Tier Calculation

### Total Score

**Sum of all dimensions**: _____ / 33

### Risk Tier

- **0-6 points**: ✅ **LOW RISK**
- **7-17 points**: ⚠️ **MEDIUM RISK**
- **18-33 points**: 🔴 **HIGH RISK**

**Your Risk Tier**: _______________________________

---

## Part 4: Feature-Specific Triggers

Check all that apply to your hook:

### Trigger Checklist

- [ ] **Custom Math**: Hook implements custom curves or non-standard math
- [ ] **Liquidity Management**: Hook manages or rebalances liquidity
- [ ] **External Dependencies**: Hook relies on oracles or external protocols
- [ ] **Autonomous Parameters**: Hook self-adjusts based on conditions
- [ ] **Price Impact**: Hook modifies fees or routing
- [ ] **Upgradeability**: Hook uses proxy or upgrade mechanism
- [ ] **TVL 5**: Hook expects $10M+ TVL

### Triggered Requirements

Based on your checks above, list additional requirements:

**Required Audits**:
- [ ] One full audit (if Medium/High risk)
- [ ] Second audit (if High risk or Custom Math)
- [ ] Math specialist audit (if Custom Math or Price Impact)

**Required Testing**:
- [ ] Unit tests (>90% coverage)
- [ ] Integration tests
- [ ] Fuzz tests (if Medium/High risk)
- [ ] Invariant tests (if High risk or Liquidity Management)
- [ ] Formal verification (recommended if TVL 5)

**Required Monitoring**:
- [ ] Basic monitoring (if Medium/High risk or External Dependencies)
- [ ] Anomaly detection (if High risk)
- [ ] Continuous monitoring (if TVL 5 or Autonomous Parameters)

**Required Programs**:
- [ ] Bug bounty (if High risk, Price Impact, Upgradeability with TVL 5)
- [ ] Emergency procedures (if TVL 5)

---

## Part 5: Security Measures Checklist

### Core Controls

- [ ] Access control implemented and minimal
- [ ] Reentrancy protection on all external calls
- [ ] Checks-effects-interactions pattern used everywhere
- [ ] OpenZeppelin libraries used where applicable
- [ ] Gas griefing protections implemented
- [ ] Balance manipulation protections implemented

### Accounting Safety

- [ ] Rounding behavior validated and tested
- [ ] Delta validation for every callback
- [ ] Invariant checks for consistency
- [ ] Safe token transfer handling (fee-on-transfer considered)
- [ ] Unbounded state growth prevented

### Upgradeability Safety (if applicable)

- [ ] Proxy pattern uses standard implementation (OZ, UUPS)
- [ ] Storage layout documented and collision-free
- [ ] Upgrades require timelock (48+ hours)
- [ ] Upgrades require multisig (5+ signers)
- [ ] Public upgrade policy documented
- [ ] Storage gap variables included

### Operational Security

- [ ] Private keys secured (hardware wallet/MPC)
- [ ] Deployment scripts reviewed
- [ ] Post-deployment verification plan
- [ ] Emergency pause mechanism (if needed)
- [ ] Incident response plan documented
- [ ] Security contact published (security@...)

### Transparency

- [ ] Code open-sourced
- [ ] Documentation comprehensive
- [ ] Audit reports published (with versions)
- [ ] Changelog maintained
- [ ] Known issues disclosed

---

## Part 6: Audit Plan

Based on your risk tier and feature triggers:

### Required Audits

**Audit 1**:
- **Type**: _______________________________
- **Firm**: _______________________________
- **Timeline**: _______________________________
- **Status**: [ ] Not started [ ] In progress [ ] Complete

**Audit 2** (if required):
- **Type**: _______________________________
- **Firm**: _______________________________
- **Timeline**: _______________________________
- **Status**: [ ] Not started [ ] In progress [ ] Complete

### Testing Plan

**Test Coverage Goal**: _____%

**Test Types**:
- [ ] Unit tests
- [ ] Integration tests
- [ ] Fuzz tests (_____ runs)
- [ ] Invariant tests
- [ ] Fork tests (mainnet/testnet)
- [ ] Gas benchmarks

**Testing Timeline**: _______________________________

### Monitoring Plan

**Monitoring Service**: _______________________________

**Metrics to Track**:
- [ ] Transaction volume
- [ ] Gas usage anomalies
- [ ] Failed transactions
- [ ] Admin actions
- [ ] Balance changes
- [ ] Oracle deviations (if applicable)
- [ ] Custom metrics: _______________________________

**Alert Thresholds**: _______________________________

### Bug Bounty Plan

**Required**: [ ] Yes [ ] No

If yes:
- **Platform**: _______________________________ (Immunefi, HackenProof, Code4rena)
- **Bounty Range**: $_______________ to $_______________
- **Launch Date**: _______________________________

---

## Part 7: Deployment Checklist

### Pre-Deployment

- [ ] All tests passing (>90% coverage)
- [ ] Gas optimization complete
- [ ] Security audits complete and issues resolved
- [ ] Documentation finalized
- [ ] Deployment script tested on testnet
- [ ] Team has reviewed all code
- [ ] Legal review complete (if applicable)

### Deployment

- [ ] Deploy to testnet first
- [ ] Verify testnet functionality (1+ week)
- [ ] Deploy to mainnet
- [ ] Verify on Etherscan
- [ ] Transfer ownership to multisig (if applicable)
- [ ] Set up monitoring
- [ ] Publish announcement

### Post-Deployment

- [ ] Monitor for first 24 hours continuously
- [ ] Check first transactions manually
- [ ] Verify all integrations working
- [ ] Publish audit reports
- [ ] Launch bug bounty (if applicable)
- [ ] Engage with community
- [ ] Prepare incident response team

---

## Part 8: Allowlist Submission Preparation

If targeting mainnet allowlist:

### Submission Checklist

- [ ] Risk assessment complete (this worksheet)
- [ ] All tier requirements met
- [ ] All feature trigger requirements met
- [ ] Audit reports available
- [ ] Test coverage >90%
- [ ] Documentation comprehensive
- [ ] Bug bounty active (if required)
- [ ] Monitoring implemented (if required)
- [ ] OPSEC procedures documented
- [ ] Emergency procedures documented (if TVL 5)

### Submission Materials

**Documents to prepare**:
- [ ] Risk assessment (this worksheet)
- [ ] Architecture documentation
- [ ] Audit reports (all versions)
- [ ] Test coverage report
- [ ] Security procedures documentation
- [ ] Economic analysis
- [ ] Deployment plan
- [ ] Team background

**Expected Review Timeline**: _______________________________

---

## Part 9: Continuous Reassessment

Security is ongoing. Reassess when:

### Reassessment Triggers

- [ ] Before each new deployment
- [ ] After any code changes
- [ ] When TVL grows 10x
- [ ] When adding new features
- [ ] After security incidents (your protocol or ecosystem)
- [ ] Every 6 months minimum

**Next Reassessment Date**: _______________________________

---

## Part 10: Notes & Action Items

### Current Blockers

1. _______________________________
2. _______________________________
3. _______________________________

### Next Steps

1. _______________________________
2. _______________________________
3. _______________________________

### Questions for Security Review

1. _______________________________
2. _______________________________
3. _______________________________

### Additional Notes

_______________________________
_______________________________
_______________________________
_______________________________

---

## Appendix: Quick Reference

### Risk Tier Requirements Summary

| Tier | Score | Audits | Bug Bounty | Monitoring | Testing |
|------|-------|--------|------------|------------|---------|
| Low | 0-6 | 1 + AI | Optional | Optional | Unit tests |
| Medium | 7-17 | 1-2 | Recommended | Recommended | Unit + Fuzz |
| High | 18-33 | 2 (1 math) | Mandatory | Mandatory | Full suite |

### Common Vulnerabilities to Check

- [ ] Reentrancy (always use ReentrancyGuard or CEI pattern)
- [ ] Integer overflow/underflow (use Solidity 0.8+)
- [ ] Front-running (consider commit-reveal or time delays)
- [ ] Oracle manipulation (use TWAP, multiple sources)
- [ ] Flash loan attacks (check for balance changes within tx)
- [ ] Griefing attacks (limit gas consumption, validate inputs)
- [ ] Access control bypass (test all permissioned functions)
- [ ] Storage collision (if using proxies)
- [ ] Denial of service (unbounded loops, external call failures)

### Resources

- **Framework**: https://docs.uniswap.org/contracts/v4/security
- **Calculator**: https://docs.google.com/spreadsheets/d/1oZdKZh13UbqVp3HujAcv-2NKP-j7NQAELhB7kyWlLRE/edit
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts/
- **Audit Firms**: Spearbit, Code4rena, OpenZeppelin, Trail of Bits
- **Monitoring**: Hypernative, Hexagate, Forta
- **Bug Bounties**: Immunefi, HackenProof, Code4rena

---

**Completed By**: _______________________________

**Date**: _______________________________

**Signature**: _______________________________

---

**Allan Robinson**
Security Assessment Worksheet - Week 3 - February 2, 2026

