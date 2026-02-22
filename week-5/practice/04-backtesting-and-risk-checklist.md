# Practice Lab 04: Backtesting and Risk Checklist for Dynamic Fee Hooks

**Goal**: Build the habit of validating mechanism design before deployment.

---

## Backtesting Checklist

- [ ] Define baseline pool (static fee) for comparison
- [ ] Define same pool with dynamic fee strategy
- [ ] Use same trade stream for both simulations
- [ ] Track LP fee revenue
- [ ] Track LP loss / IL proxy
- [ ] Track trader execution quality (slippage / total cost)
- [ ] Track arbitrage volume share
- [ ] Track fee distribution over time

---

## Risk Checklist

### Technical
- [ ] Dynamic fee flag enforcement
- [ ] Fee bounds/clamps
- [ ] Override flag set correctly
- [ ] No overflow/underflow in fee math
- [ ] Same-block behavior deterministic

### Economic
- [ ] Fee rule not obviously exploitable
- [ ] Parameter sensitivity tested
- [ ] Pool remains competitive for target users
- [ ] LP benefit measured, not assumed

### Operational
- [ ] Monitoring events / dashboards planned
- [ ] Fallback behavior defined
- [ ] Emergency disable strategy (if applicable)

---

## Deliverable

Write a one-page memo:
- strategy tested
- assumptions
- results
- why you would (or would not) deploy it

