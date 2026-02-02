# Hook Design Patterns & Best Practices

**Author**: Allan Robinson
**Date**: February 2, 2026
**Context**: Advanced patterns from Week 3 learnings

---

## Introduction

After studying the security framework and examining production hooks like Clanker v4, I've identified key design patterns that make hooks both secure and effective. This guide documents patterns I'll use in my own hooks.

---

## Pattern 1: Checks-Effects-Interactions (CEI)

### The Problem

Reentrancy attacks occur when external calls are made before state is updated.

```
┌─────────────────────────────────────────┐
│       VULNERABLE PATTERN                │
├─────────────────────────────────────────┤
│                                         │
│  function afterSwap(...) {              │
│      externalCall();      // ❌ WRONG! │
│      updateState();       // Too late  │
│  }                                      │
│                                         │
│  Attacker can reenter before state     │
│  is updated and exploit inconsistency. │
│                                         │
└─────────────────────────────────────────┘
```

### The Solution

Always follow this order:
1. **Checks**: Validate inputs and conditions
2. **Effects**: Update state
3. **Interactions**: Make external calls

```solidity
// CORRECT: CEI Pattern
function afterSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) internal override returns (bytes4, int128) {
    // 1. CHECKS
    require(sender != address(0), "Invalid sender");
    require(!paused, "Hook paused");

    PoolId poolId = key.toId();
    uint256 points = POINTS_PER_SWAP;

    // 2. EFFECTS (update state BEFORE external calls)
    userPoints[sender][poolId] += points;
    totalSwaps[poolId]++;
    lastSwapTime[sender] = block.timestamp;

    // Emit events (also part of effects)
    emit PointsAwarded(sender, poolId, points);
    emit SwapExecuted(sender, poolId);

    // 3. INTERACTIONS (external calls LAST)
    if (shouldNotifyOracle) {
        try oracle.updatePrice(poolId, getCurrentPrice(key)) {
            // Oracle updated successfully
        } catch {
            // Handle failure gracefully, don't revert
        }
    }

    return (BaseHook.afterSwap.selector, 0);
}
```

### Key Takeaways

- ✅ Always update storage before external calls
- ✅ Emit events before external calls
- ✅ Use try-catch for optional external calls
- ❌ Never trust external contract behavior

---

## Pattern 2: Helper Functions for DRY Code

### The Problem

Repetitive logic across multiple hook functions leads to:
- More code to audit
- Higher gas costs
- Maintenance burden
- Risk of inconsistency

### The Solution

Extract common logic into internal helper functions.

```solidity
// BEFORE: Repetitive code
function afterSwap(...) internal override returns (bytes4, int128) {
    PoolId poolId = key.toId();
    userPoints[sender][poolId] += POINTS_PER_SWAP;
    emit PointsAwarded(sender, poolId, POINTS_PER_SWAP);
    totalSwaps[poolId]++;
    return (BaseHook.afterSwap.selector, 0);
}

function afterAddLiquidity(...) internal override returns (bytes4, BalanceDelta) {
    PoolId poolId = key.toId();
    userPoints[sender][poolId] += POINTS_PER_LIQUIDITY;
    emit PointsAwarded(sender, poolId, POINTS_PER_LIQUIDITY);
    totalLiquidityOps[poolId]++;
    return (BaseHook.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
}

// AFTER: DRY with helper
function _assignPoints(
    address user,
    PoolId poolId,
    uint256 points,
    string memory action
) internal {
    userPoints[user][poolId] += points;
    emit PointsAwarded(user, poolId, points);
    emit ActionPerformed(user, poolId, action);
}

function afterSwap(...) internal override returns (bytes4, int128) {
    PoolId poolId = key.toId();
    _assignPoints(sender, poolId, POINTS_PER_SWAP, "swap");
    totalSwaps[poolId]++;
    return (BaseHook.afterSwap.selector, 0);
}

function afterAddLiquidity(...) internal override returns (bytes4, BalanceDelta) {
    PoolId poolId = key.toId();
    _assignPoints(sender, poolId, POINTS_PER_LIQUIDITY, "addLiquidity");
    totalLiquidityOps[poolId]++;
    return (BaseHook.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
}
```

### Benefits

- 🔥 **Gas savings**: Function calls are cheaper than duplicated code
- 🔍 **Easier auditing**: Review logic once instead of N times
- 🛠️ **Maintainability**: Fix bugs in one place
- ✅ **Consistency**: Guaranteed same behavior everywhere

---

## Pattern 3: Graceful External Call Handling

### The Problem

External dependencies can fail unexpectedly:
- Oracle returns stale data
- External protocol is paused
- Network issues cause timeouts

### The Solution

Always wrap external calls with error handling.

```solidity
// Pattern 3A: Try-Catch for Optional Calls
function afterSwap(...) internal override returns (bytes4, int128) {
    // Core logic first (never depends on external call)
    PoolId poolId = key.toId();
    userPoints[sender][poolId] += POINTS_PER_SWAP;

    // Optional external call with try-catch
    try oracle.latestRoundData() returns (
        uint80 roundId,
        int256 price,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        // Success: Use oracle data for bonus points
        if (block.timestamp - updatedAt < 1 hours) {
            uint256 bonus = calculateBonus(uint256(price));
            userPoints[sender][poolId] += bonus;
        }
    } catch {
        // Failure: Continue without bonus
        emit OracleFailed(poolId, block.timestamp);
    }

    return (BaseHook.afterSwap.selector, 0);
}

// Pattern 3B: Circuit Breaker for Critical Calls
mapping(address => bool) public oracleHealthy;
mapping(address => uint256) public oracleLastSuccess;

function _checkOracleHealth(address oracleAddr) internal view returns (bool) {
    // Oracle must have succeeded in last 24 hours
    return oracleHealthy[oracleAddr] &&
           block.timestamp - oracleLastSuccess[oracleAddr] < 24 hours;
}

function beforeSwap(...) external view returns (bytes4, BeforeSwapDelta, uint24) {
    if (!_checkOracleHealth(priceOracle)) {
        // Oracle unhealthy: Use fallback or pause
        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            10000  // Higher fee in degraded mode
        );
    }

    // Normal operation
    uint256 price = _getOraclePrice();
    uint24 dynamicFee = _calculateFee(price);

    return (
        BaseHook.beforeSwap.selector,
        BeforeSwapDeltaLibrary.ZERO_DELTA,
        dynamicFee
    );
}

// Admin function to update oracle health
function updateOracleHealth(address oracleAddr, bool healthy) external onlyOwner {
    oracleHealthy[oracleAddr] = healthy;
    if (healthy) {
        oracleLastSuccess[oracleAddr] = block.timestamp;
    }
}

// Pattern 3C: Fallback Mechanisms
function _getPrice() internal view returns (uint256) {
    // Try primary oracle
    try primaryOracle.latestPrice() returns (uint256 price) {
        if (_isPriceValid(price)) {
            return price;
        }
    } catch {}

    // Try secondary oracle
    try secondaryOracle.getPrice() returns (uint256 price) {
        if (_isPriceValid(price)) {
            return price;
        }
    } catch {}

    // Fallback to TWAP
    return _getTWAPPrice();
}
```

### Key Principles

- ✅ Never let external failures block core functionality
- ✅ Always have fallback mechanisms
- ✅ Log all failures for monitoring
- ✅ Consider circuit breakers for critical paths

---

## Pattern 4: Events for Off-Chain Indexing

### The Problem

Storing all historical data on-chain is expensive:
- Every storage slot costs ~20,000 gas (new) or ~5,000 gas (update)
- Historical queries require iterating storage
- Scaling issues as data grows

### The Solution

Use events for data that only frontends/indexers need.

```solidity
// WRONG: Expensive on-chain storage for history
contract PointsHook is BaseHook {
    struct SwapRecord {
        address user;
        uint256 timestamp;
        uint256 pointsEarned;
    }

    // ❌ EXPENSIVE: Array grows unbounded
    mapping(PoolId => SwapRecord[]) public swapHistory;

    function afterSwap(...) internal override returns (bytes4, int128) {
        // 20,000+ gas per swap just for history!
        swapHistory[poolId].push(SwapRecord({
            user: sender,
            timestamp: block.timestamp,
            pointsEarned: POINTS_PER_SWAP
        }));

        // ...
    }
}

// RIGHT: Events for historical data
contract PointsHook is BaseHook {
    // Events are ~1,500 gas per indexed topic
    event SwapExecuted(
        address indexed user,
        PoolId indexed poolId,
        uint256 timestamp,
        uint256 pointsEarned
    );

    // Only store current state (what contracts need)
    mapping(address => mapping(PoolId => uint256)) public userPoints;

    function afterSwap(...) internal override returns (bytes4, int128) {
        PoolId poolId = key.toId();

        // Update state
        userPoints[sender][poolId] += POINTS_PER_SWAP;

        // Emit event (cheap!)
        emit SwapExecuted(sender, poolId, block.timestamp, POINTS_PER_SWAP);

        return (BaseHook.afterSwap.selector, 0);
    }
}
```

### Event Design Best Practices

```solidity
// Good event design
event PointsAwarded(
    address indexed user,      // ✅ Indexed: Can filter by user
    PoolId indexed poolId,     // ✅ Indexed: Can filter by pool
    uint256 points,            // ✅ Not indexed: Just data
    uint256 timestamp,         // ✅ Useful for sorting
    string action              // ✅ Context (swap vs liquidity)
);

// Query examples (off-chain):
// - Get all points for user X: Filter by user
// - Get all activity in pool Y: Filter by poolId
// - Get all swaps in last 24h: Filter by timestamp
```

### Storage vs Events Decision Matrix

| Data | Storage | Events |
|------|---------|--------|
| Current user balances | ✅ Yes | ✅ Yes (optional) |
| Total swaps counter | ✅ Yes | ❌ No |
| Historical swap details | ❌ No | ✅ Yes |
| User's last action time | ✅ Yes | ❌ No |
| All swaps ever (for UI) | ❌ No | ✅ Yes |
| Pool configuration | ✅ Yes | ❌ No |

**Rule of thumb**: If smart contracts need it → Storage. If only humans need it → Events.

---

## Pattern 5: Access Control Patterns

### Pattern 5A: Immutable (No Admin)

**Best for**: Simple, well-tested hooks with no need for changes.

```solidity
// Fully immutable hook
contract SimplePointsHook is BaseHook {
    // Constants defined at deployment
    uint256 public immutable POINTS_PER_SWAP;

    constructor(IPoolManager _poolManager, uint256 _pointsPerSwap) BaseHook(_poolManager) {
        POINTS_PER_SWAP = _pointsPerSwap;
    }

    // No admin functions
    // No upgrade mechanism
    // No pause function

    // ✅ Highest security: No attack surface for admin key compromise
    // ❌ No flexibility: Can't fix bugs or adjust parameters
}
```

### Pattern 5B: Minimal Admin (Emergency Only)

**Best for**: Production hooks that might need emergency shutdown.

```solidity
// Minimal admin for emergency pause only
contract PointsHook is BaseHook {
    address public immutable admin;
    bool public paused;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        admin = msg.sender;
    }

    // ONLY admin function: Emergency pause
    function pause() external {
        require(msg.sender == admin, "Only admin");
        require(!paused, "Already paused");
        paused = true;
        emit Paused(block.timestamp);
    }

    // No unpause function (requires new deployment)
    // No other admin powers
    // No parameter updates

    modifier whenNotPaused() {
        require(!paused, "Hook paused");
        _;
    }

    function afterSwap(...) internal override whenNotPaused returns (bytes4, int128) {
        // Hook logic
    }
}
```

### Pattern 5C: Multisig Controlled

**Best for**: Hooks with adjustable parameters requiring governance.

```solidity
// Multisig with timelock
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract GovernedHook is BaseHook, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    uint256 public pointsPerSwap;

    // Pending parameter updates
    struct PendingUpdate {
        uint256 newValue;
        uint256 effectiveTime;
    }
    mapping(bytes32 => PendingUpdate) public pendingUpdates;

    uint256 public constant TIMELOCK_DURATION = 48 hours;

    constructor(
        IPoolManager _poolManager,
        address multisig
    ) BaseHook(_poolManager) {
        _grantRole(DEFAULT_ADMIN_ROLE, multisig);
        _grantRole(ADMIN_ROLE, multisig);
    }

    // Step 1: Propose parameter change
    function proposePointsUpdate(uint256 newPoints) external onlyRole(ADMIN_ROLE) {
        bytes32 updateId = keccak256("pointsPerSwap");
        pendingUpdates[updateId] = PendingUpdate({
            newValue: newPoints,
            effectiveTime: block.timestamp + TIMELOCK_DURATION
        });

        emit UpdateProposed(updateId, newPoints, block.timestamp + TIMELOCK_DURATION);
    }

    // Step 2: Execute after timelock (anyone can call)
    function executePointsUpdate() external {
        bytes32 updateId = keccak256("pointsPerSwap");
        PendingUpdate memory update = pendingUpdates[updateId];

        require(update.effectiveTime > 0, "No pending update");
        require(block.timestamp >= update.effectiveTime, "Timelock not expired");

        pointsPerSwap = update.newValue;
        delete pendingUpdates[updateId];

        emit UpdateExecuted(updateId, update.newValue);
    }

    // Cancel during timelock period
    function cancelUpdate(bytes32 updateId) external onlyRole(ADMIN_ROLE) {
        require(pendingUpdates[updateId].effectiveTime > 0, "No update to cancel");
        delete pendingUpdates[updateId];
        emit UpdateCancelled(updateId);
    }
}
```

### Access Control Decision Tree

```
┌─────────────────────────────────────────┐
│     "Does my hook need an admin?"       │
└─────────────────────────────────────────┘
                   │
                   ▼
        ┌──────────┴──────────┐
        │                     │
    Parameters              Fully
    might need           determined
    adjustment?          at deploy?
        │                     │
        ▼                     ▼
    Need emergency       Immutable
    pause?                Pattern
        │
        ▼
    ┌───┴────┐
    │        │
  High      Low
  TVL?      TVL?
    │        │
    ▼        ▼
Multisig   Minimal
+Timelock   Admin
```

---

## Pattern 6: Gas Optimization Techniques

### Technique 1: Pack Storage Variables

```solidity
// WRONG: Each variable uses full slot (32 bytes)
contract Unoptimized {
    uint8 status;        // Slot 0: 1 byte + 31 wasted
    uint256 counter;     // Slot 1: 32 bytes
    uint8 flags;         // Slot 2: 1 byte + 31 wasted
    address owner;       // Slot 3: 20 bytes + 12 wasted
}
// Total: 4 SLOAD operations

// RIGHT: Pack related variables
contract Optimized {
    uint256 counter;     // Slot 0: 32 bytes (full)

    // Slot 1: Packed (8 + 8 + 160 = 176 bits = 22 bytes)
    uint8 status;        // 1 byte
    uint8 flags;         // 1 byte
    address owner;       // 20 bytes
    // 10 bytes free in this slot for future use
}
// Total: 2 SLOAD operations (50% savings!)
```

### Technique 2: Use Immutable for Constants

```solidity
// WRONG: Storage variable (2,100 gas per read)
contract Unoptimized {
    uint256 public pointsPerSwap = 100;
}

// RIGHT: Immutable (3 gas per read)
contract Optimized {
    uint256 public immutable POINTS_PER_SWAP;

    constructor(uint256 _points) {
        POINTS_PER_SWAP = _points;
    }
}

// BEST: True constant if value known at compile time (0 gas!)
contract BestCase {
    uint256 public constant POINTS_PER_SWAP = 100;
}
```

### Technique 3: Cache Storage Reads

```solidity
// WRONG: Multiple storage reads
function afterSwap(...) internal override returns (bytes4, int128) {
    // Each userPoints[sender][poolId] read costs 2,100 gas!
    if (userPoints[sender][poolId] > 1000) {
        userPoints[sender][poolId] += 50;  // Read + Write
    } else {
        userPoints[sender][poolId] += 100; // Read + Write
    }

    if (userPoints[sender][poolId] > 10000) {  // Another read!
        // Bonus logic
    }
}
// Total: 4+ storage reads

// RIGHT: Cache in memory
function afterSwap(...) internal override returns (bytes4, int128) {
    uint256 currentPoints = userPoints[sender][poolId];  // 1 read

    if (currentPoints > 1000) {
        currentPoints += 50;
    } else {
        currentPoints += 100;
    }

    if (currentPoints > 10000) {  // Memory read (3 gas)
        // Bonus logic
    }

    userPoints[sender][poolId] = currentPoints;  // 1 write
}
// Total: 1 storage read + 1 write (major savings!)
```

### Technique 4: Use Unchecked for Safe Math

```solidity
// Solidity 0.8+ adds overflow checks (extra gas)
function distributPoints(address[] calldata users) external {
    uint256 totalPoints = 0;

    // WRONG: Overflow check on every iteration
    for (uint256 i = 0; i < users.length; i++) {
        totalPoints += POINTS_PER_USER;
    }

    // RIGHT: Use unchecked where safe
    for (uint256 i = 0; i < users.length;) {
        totalPoints += POINTS_PER_USER;

        unchecked {
            ++i;  // i can never overflow in realistic scenario
        }
    }
}
```

### Technique 5: Short-Circuit Logic

```solidity
// WRONG: Always evaluates all conditions
function canSwap(address user, PoolId poolId) public view returns (bool) {
    return hasPermission(user) &&  // Expensive call
           isPoolActive(poolId) &&  // Expensive call
           balanceOf(user) > 0;     // Cheap check
}

// RIGHT: Cheap checks first
function canSwap(address user, PoolId poolId) public view returns (bool) {
    return balanceOf(user) > 0 &&      // Cheap (fails fast for most users)
           isPoolActive(poolId) &&     // Medium cost
           hasPermission(user);        // Expensive (rarely reached)
}
```

---

## Pattern 7: Safe Math for Custom Calculations

### Using FullMath Library

```solidity
import {FullMath} from "@uniswap/v4-core/libraries/FullMath.sol";

// WRONG: Direct division can lose precision
function calculateFee(uint256 amount) public pure returns (uint256) {
    return (amount * 30) / 10000;  // 0.3% fee
    // Problem: Loses precision for small amounts
}

// RIGHT: Use FullMath for precise calculations
function calculateFee(uint256 amount) public pure returns (uint256) {
    return FullMath.mulDiv(amount, 30, 10000);
    // Handles precision correctly for all amounts
}

// Example: Custom bonding curve
function getBuyPrice(uint256 supply) public pure returns (uint256) {
    // Price = supply^2 / 1000000
    return FullMath.mulDiv(
        supply,
        supply,
        1000000
    );
}
```

### Avoiding Overflow/Underflow

```solidity
// Even with Solidity 0.8+, be careful with large numbers
function calculateReward(
    uint256 amount,
    uint256 multiplier,
    uint256 duration
) public pure returns (uint256) {
    // WRONG: Can overflow
    // return amount * multiplier * duration / 1000;

    // RIGHT: Break into steps with checks
    uint256 step1 = FullMath.mulDiv(amount, multiplier, 1000);
    return FullMath.mulDiv(step1, duration, 1);
}
```

---

## Pattern 8: Testing Patterns

### Pattern 8A: Helper Functions in Tests

```solidity
// Test helper pattern
contract PointsHookTest is Test {
    PointsHook hook;

    // Helper: Execute swap and return points earned
    function _swapAndGetPoints(address user, uint256 amount) internal returns (uint256) {
        uint256 pointsBefore = hook.getPoints(user, poolId);

        vm.prank(user);
        swap(poolKey, amount);

        uint256 pointsAfter = hook.getPoints(user, poolId);
        return pointsAfter - pointsBefore;
    }

    function testSwapAwardsCorrectPoints() public {
        uint256 pointsEarned = _swapAndGetPoints(alice, 1 ether);
        assertEq(pointsEarned, POINTS_PER_SWAP);
    }

    function testMultipleSwaps() public {
        uint256 points1 = _swapAndGetPoints(alice, 1 ether);
        uint256 points2 = _swapAndGetPoints(alice, 2 ether);

        assertEq(points1 + points2, POINTS_PER_SWAP * 2);
    }
}
```

### Pattern 8B: Invariant Testing

```solidity
// Invariants that should ALWAYS hold
contract PointsHookInvariants is Test {
    function invariant_totalPointsMatchesSum() public {
        // Sum of all user points should equal total distributed
        uint256 sumUserPoints = 0;
        for (uint256 i = 0; i < users.length; i++) {
            sumUserPoints += hook.getPoints(users[i], poolId);
        }

        assertEq(sumUserPoints, hook.totalPointsDistributed(poolId));
    }

    function invariant_pointsNeverDecrease() public {
        // Points can only increase, never decrease
        for (uint256 i = 0; i < users.length; i++) {
            uint256 currentPoints = hook.getPoints(users[i], poolId);
            assertGe(currentPoints, previousPoints[users[i]]);
            previousPoints[users[i]] = currentPoints;
        }
    }
}
```

---

## Pattern 9: Documentation Patterns

### Inline Documentation

```solidity
/// @title Points Hook - Awards points for trading activity
/// @author Allan Robinson
/// @notice This hook tracks user activity and awards points
/// @dev Implements afterSwap and afterAddLiquidity hooks
contract PointsHook is BaseHook {

    /// @notice Points awarded per swap transaction
    /// @dev Immutable after deployment for security
    uint256 public immutable POINTS_PER_SWAP;

    /// @notice Mapping of user addresses to pool IDs to point balances
    /// @dev nested mapping: user => poolId => points
    mapping(address => mapping(PoolId => uint256)) public userPoints;

    /// @notice Assigns points to a user for a specific action
    /// @dev Internal helper to maintain DRY principle
    /// @param user The address receiving points
    /// @param poolId The pool where action occurred
    /// @param points The number of points to award
    function _assignPoints(
        address user,
        PoolId poolId,
        uint256 points
    ) internal {
        userPoints[user][poolId] += points;
        emit PointsAwarded(user, poolId, points);
    }

    /// @inheritdoc BaseHook
    /// @notice Called after every swap in the pool
    /// @dev Awards POINTS_PER_SWAP to the sender
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        // Implementation
    }
}
```

---

## Pattern 10: Emergency Response Patterns

### Circuit Breaker Pattern

```solidity
contract RobustHook is BaseHook {
    bool public emergency;
    address public immutable admin;

    // Emergency metrics
    uint256 public lastSwapGasUsed;
    uint256 public constant MAX_GAS_THRESHOLD = 500000;

    uint256 public failedOracleCalls;
    uint256 public constant MAX_ORACLE_FAILURES = 10;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier notEmergency() {
        require(!emergency, "Emergency mode active");
        _;
    }

    // Automatic circuit breaker
    function _checkCircuitBreaker() internal {
        // Check gas usage
        if (lastSwapGasUsed > MAX_GAS_THRESHOLD) {
            emergency = true;
            emit EmergencyActivated("High gas usage", block.timestamp);
        }

        // Check oracle health
        if (failedOracleCalls > MAX_ORACLE_FAILURES) {
            emergency = true;
            emit EmergencyActivated("Oracle failures", block.timestamp);
        }
    }

    // Manual emergency trigger
    function activateEmergency() external onlyAdmin {
        emergency = true;
        emit EmergencyActivated("Manual activation", block.timestamp);
    }

    // Hook functions check emergency state
    function afterSwap(...) internal override notEmergency returns (bytes4, int128) {
        uint256 gasBefore = gasleft();

        // Hook logic

        lastSwapGasUsed = gasBefore - gasleft();
        _checkCircuitBreaker();

        return (BaseHook.afterSwap.selector, 0);
    }
}
```

---

## My Design Checklist

When building any hook, I'll verify:

### Security
- [ ] CEI pattern used everywhere
- [ ] No reentrancy vulnerabilities
- [ ] External calls wrapped in try-catch
- [ ] Access control minimal and secure
- [ ] All math uses safe operations

### Gas Optimization
- [ ] Storage variables packed
- [ ] Immutable used for constants
- [ ] Storage reads cached
- [ ] Events used instead of storage where possible
- [ ] Short-circuit logic for conditionals

### Code Quality
- [ ] Helper functions eliminate repetition
- [ ] Clear, descriptive variable names
- [ ] Comprehensive NatSpec documentation
- [ ] Consistent code style
- [ ] No magic numbers (use constants)

### Testing
- [ ] >90% code coverage
- [ ] Invariant tests for critical properties
- [ ] Fuzz tests for edge cases
- [ ] Integration tests with real pools
- [ ] Gas benchmarks documented

### Operational
- [ ] Emergency procedures defined
- [ ] Circuit breakers implemented (if needed)
- [ ] Monitoring plan documented
- [ ] Upgrade strategy clear (or immutable)

---

**Allan Robinson**
Hook Design Patterns - Week 3 - February 2, 2026

