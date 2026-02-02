# Week 3: Security & Design Pattern Exercises

**Author**: Allan Robinson
**Date**: February 2, 2026
**Focus**: Practical security and design pattern implementation

---

## Exercise 1: Risk Assessment Practice

### Task

Complete a security assessment for the following hook concept:

**Hook Name**: Dynamic Fee Optimizer Hook

**Description**:
- Adjusts pool fees based on volatility
- Uses Chainlink oracle for price data
- Implements custom volatility calculation
- Admin can update fee parameters
- Expected TVL: $5M

### Your Task

1. Score the hook across all 9 risk dimensions
2. Determine risk tier (Low/Medium/High)
3. List all required security measures
4. Identify potential vulnerabilities

<details>
<summary>Solution</summary>

### Risk Scoring

1. **Complexity (0-5)**: 3 points
   - Multiple hook functions (beforeSwap)
   - Custom volatility calculations
   - Parameter management logic

2. **Custom Math (0-5)**: 3 points
   - Volatility calculation algorithm
   - Fee adjustment formula

3. **External Dependencies (0-3)**: 1 point
   - Chainlink oracle (trusted)

4. **External Liquidity (0-3)**: 0 points
   - No external liquidity held

5. **TVL Potential (0-5)**: 3 points
   - Expected $5M TVL ($1M-$10M bracket)

6. **Team Maturity (0-3)**: 0 points
   - Assuming first deployment

7. **Upgradeability (0-3)**: 1 point
   - Admin can update parameters

8. **Autonomous Updates (0-3)**: 2 points
   - Oracle-driven fee adjustments

9. **Price Impact (0-3)**: 3 points
   - Directly modifies swap fees

**Total Score**: 16 points = **MEDIUM RISK**

### Feature Triggers

- ✅ Custom Math (volatility calculation)
- ✅ External Dependencies (oracle)
- ✅ Price Impact (fee modification)

### Required Security Measures

**Audits**:
- ✅ One full audit (Medium Risk requirement)
- ✅ Math specialist audit (Custom Math + Price Impact triggers)

**Testing**:
- ✅ Unit tests (>90% coverage)
- ✅ Fuzz tests for volatility calculation
- ✅ Integration tests with oracle
- ✅ Scenario testing for oracle failures

**Monitoring**:
- ✅ Oracle health monitoring (External Dependencies trigger)
- ✅ Fee adjustment tracking
- ✅ Gas usage monitoring

**Programs**:
- ✅ Bug bounty recommended (Medium Risk + Price Impact)

### Potential Vulnerabilities

1. **Oracle Manipulation**
   - Risk: Attacker could influence price oracle
   - Mitigation: Use TWAP, multiple oracles, sanity checks

2. **Fee Griefing**
   - Risk: Extreme volatility could make fees too high/low
   - Mitigation: Set min/max fee bounds

3. **Admin Key Compromise**
   - Risk: Admin could set malicious parameters
   - Mitigation: Use multisig + timelock

4. **Gas Cost Attack**
   - Risk: Complex calculations could exceed block gas limit
   - Mitigation: Gas optimization, circuit breakers

</details>

---

## Exercise 2: Fix the Vulnerable Hook

### Task

The following hook has **3 critical security vulnerabilities**. Identify and fix them.

```solidity
contract VulnerablePointsHook is BaseHook {
    mapping(address => mapping(PoolId => uint256)) public userPoints;
    address public admin;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        admin = msg.sender;
    }

    // Vulnerability 1: Where is it?
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        PoolId poolId = key.toId();

        // Award points
        _notifyExternalSystem(sender, poolId);
        userPoints[sender][poolId] += 100;

        return (BaseHook.afterSwap.selector, 0);
    }

    // Vulnerability 2: Where is it?
    function _notifyExternalSystem(address user, PoolId poolId) internal {
        (bool success, ) = externalNotifier.call(
            abi.encodeWithSignature("notify(address,bytes32)", user, PoolId.unwrap(poolId))
        );
        require(success, "Notification failed");
    }

    // Vulnerability 3: Where is it?
    function updateAdmin(address newAdmin) external {
        admin = newAdmin;
    }
}
```

<details>
<summary>Solution</summary>

### Vulnerabilities Identified

**Vulnerability 1: Violates CEI Pattern (Reentrancy Risk)**
- **Location**: `afterSwap` function
- **Problem**: External call (`_notifyExternalSystem`) before state update
- **Risk**: Reentrancy attack could double-count points

**Vulnerability 2: Reverts on External Call Failure**
- **Location**: `_notifyExternalSystem` function
- **Problem**: `require(success)` will revert entire swap if notification fails
- **Risk**: External system can DOS the entire pool

**Vulnerability 3: No Access Control on Admin Update**
- **Location**: `updateAdmin` function
- **Problem**: Anyone can change the admin address
- **Risk**: Complete compromise of admin functions

### Fixed Version

```solidity
contract SecurePointsHook is BaseHook {
    mapping(address => mapping(PoolId => uint256)) public userPoints;
    address public immutable admin;  // FIX 3: Make immutable

    event ExternalNotificationFailed(address user, PoolId poolId);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        admin = msg.sender;
    }

    // FIX 1: Follow CEI pattern
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        PoolId poolId = key.toId();

        // EFFECTS: Update state BEFORE external calls
        userPoints[sender][poolId] += 100;

        // INTERACTIONS: External calls LAST
        _notifyExternalSystem(sender, poolId);

        return (BaseHook.afterSwap.selector, 0);
    }

    // FIX 2: Don't revert on external failure
    function _notifyExternalSystem(address user, PoolId poolId) internal {
        try externalNotifier.notify(user, PoolId.unwrap(poolId)) {
            // Success - nothing to do
        } catch {
            // Failure - log and continue
            emit ExternalNotificationFailed(user, poolId);
        }
    }

    // FIX 3: Remove updateAdmin entirely (immutable is better)
    // Or if updates needed, add access control:
    // function updateAdmin(address newAdmin) external {
    //     require(msg.sender == admin, "Only admin");
    //     require(newAdmin != address(0), "Invalid address");
    //     admin = newAdmin;
    //     emit AdminUpdated(newAdmin);
    // }
}
```

### Key Lessons

1. **Always CEI**: Checks → Effects → Interactions
2. **Never trust external calls**: Use try-catch
3. **Protect privileged functions**: Require access control

</details>

---

## Exercise 3: Implement Gas-Optimized Storage

### Task

Refactor the following hook to minimize gas costs through proper storage packing.

```solidity
contract UnoptimizedHook is BaseHook {
    // Current implementation (inefficient)
    mapping(PoolId => uint8) public poolStatus;           // 1 byte
    mapping(PoolId => uint256) public totalSwaps;         // 32 bytes
    mapping(PoolId => uint8) public feeMultiplier;        // 1 byte
    mapping(PoolId => address) public poolOwner;          // 20 bytes
    mapping(PoolId => uint256) public lastSwapTime;       // 32 bytes
    mapping(PoolId => bool) public isPaused;              // 1 byte

    // Each pool uses 6 storage slots (very expensive!)
}
```

<details>
<summary>Solution</summary>

```solidity
contract OptimizedHook is BaseHook {
    // Optimized: Pack related data into structs
    struct PoolData {
        // Slot 1: Pack small values (25 bytes used, 7 free)
        uint8 status;           // 1 byte
        uint8 feeMultiplier;    // 1 byte
        bool isPaused;          // 1 byte
        address poolOwner;      // 20 bytes
        uint16 reserved;        // 2 bytes for future use

        // Slot 2: Large values get their own slot
        uint256 totalSwaps;     // 32 bytes

        // Slot 3: Another large value
        uint256 lastSwapTime;   // 32 bytes
    }

    mapping(PoolId => PoolData) public poolData;

    // Now each pool uses 3 storage slots (50% savings!)

    // Accessor functions maintain same interface
    function poolStatus(PoolId poolId) external view returns (uint8) {
        return poolData[poolId].status;
    }

    function totalSwaps(PoolId poolId) external view returns (uint256) {
        return poolData[poolId].totalSwaps;
    }

    // Update function shows gas savings
    function updatePoolData(
        PoolId poolId,
        uint8 newStatus,
        uint8 newMultiplier
    ) external {
        PoolData storage data = poolData[poolId];

        // Single SLOAD to load entire slot 1
        // Modify in memory
        data.status = newStatus;
        data.feeMultiplier = newMultiplier;
        // Single SSTORE to save entire slot 1

        // vs original: 2 SLOADs + 2 SSTOREs
    }
}
```

### Gas Comparison

**Original**:
- 6 storage slots per pool
- Reading all data: 6 SLOADs = 12,600 gas
- Writing all data: 6 SSTOREs = ~120,000 gas

**Optimized**:
- 3 storage slots per pool (50% reduction)
- Reading all data: 3 SLOADs = 6,300 gas (50% savings!)
- Writing all data: 3 SSTOREs = ~60,000 gas (50% savings!)

</details>

---

## Exercise 4: Implement Circuit Breaker Pattern

### Task

Add a circuit breaker to this oracle-dependent hook that automatically pauses if the oracle fails too many times.

```solidity
contract OracleDependentHook is BaseHook {
    IPriceOracle public oracle;

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external view returns (bytes4, BeforeSwapDelta, uint24) {
        // Get price from oracle
        uint256 price = oracle.getPrice();

        // Calculate dynamic fee based on price
        uint24 dynamicFee = _calculateFee(price);

        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            dynamicFee
        );
    }
}
```

<details>
<summary>Solution</summary>

```solidity
contract RobustOracleHook is BaseHook {
    IPriceOracle public oracle;
    address public immutable admin;

    // Circuit breaker state
    bool public emergency;
    uint256 public consecutiveFailures;
    uint256 public lastSuccessTime;

    uint256 public constant MAX_FAILURES = 3;
    uint256 public constant STALENESS_THRESHOLD = 1 hours;
    uint24 public constant FALLBACK_FEE = 3000; // 0.3%

    event CircuitBreakerTriggered(string reason, uint256 timestamp);
    event OracleFailure(uint256 failureCount);
    event EmergencyResolved(uint256 timestamp);

    constructor(
        IPoolManager _poolManager,
        IPriceOracle _oracle
    ) BaseHook(_poolManager) {
        oracle = _oracle;
        admin = msg.sender;
        lastSuccessTime = block.timestamp;
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        // Check circuit breaker
        if (emergency) {
            // Emergency mode: Use fallback fee
            return (
                BaseHook.beforeSwap.selector,
                BeforeSwapDeltaLibrary.ZERO_DELTA,
                FALLBACK_FEE
            );
        }

        // Try to get oracle price
        (bool success, uint256 price) = _getOraclePriceSafe();

        if (!success) {
            // Oracle failed
            consecutiveFailures++;
            emit OracleFailure(consecutiveFailures);

            // Check if we should trigger circuit breaker
            if (_shouldTriggerCircuitBreaker()) {
                emergency = true;
                emit CircuitBreakerTriggered(
                    "Too many oracle failures",
                    block.timestamp
                );
            }

            // Use fallback fee
            return (
                BaseHook.beforeSwap.selector,
                BeforeSwapDeltaLibrary.ZERO_DELTA,
                FALLBACK_FEE
            );
        }

        // Success! Reset failure counter
        consecutiveFailures = 0;
        lastSuccessTime = block.timestamp;

        // Calculate dynamic fee
        uint24 dynamicFee = _calculateFee(price);

        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            dynamicFee
        );
    }

    function _getOraclePriceSafe() internal view returns (bool, uint256) {
        try oracle.getPrice() returns (uint256 price) {
            // Validate price is reasonable
            if (price == 0 || price > type(uint128).max) {
                return (false, 0);
            }
            return (true, price);
        } catch {
            return (false, 0);
        }
    }

    function _shouldTriggerCircuitBreaker() internal view returns (bool) {
        // Trigger if:
        // 1. Too many consecutive failures
        if (consecutiveFailures >= MAX_FAILURES) {
            return true;
        }

        // 2. Oracle hasn't succeeded in too long
        if (block.timestamp - lastSuccessTime > STALENESS_THRESHOLD) {
            return true;
        }

        return false;
    }

    function _calculateFee(uint256 price) internal pure returns (uint24) {
        // Custom fee logic based on price
        // (implementation details)
        return 3000;
    }

    // Admin function to resolve emergency
    function resolveEmergency() external {
        require(msg.sender == admin, "Only admin");
        require(emergency, "Not in emergency");

        // Test oracle is working
        (bool success, ) = _getOraclePriceSafe();
        require(success, "Oracle still failing");

        // Reset state
        emergency = false;
        consecutiveFailures = 0;
        lastSuccessTime = block.timestamp;

        emit EmergencyResolved(block.timestamp);
    }
}
```

### Key Features

1. **Automatic Triggering**: Circuit breaker activates automatically
2. **Multiple Triggers**: Consecutive failures OR staleness
3. **Graceful Degradation**: Falls back to default fee
4. **Manual Recovery**: Admin can test and resolve
5. **Transparent**: Events log all state changes

</details>

---

## Exercise 5: Design MEV Protection Hook

### Task

Design a hook that protects users from sandwich attacks using a commit-reveal scheme.

### Requirements

1. Users commit to swap parameters in transaction 1
2. Actual swap executes in transaction 2 (next block)
3. Parameters are validated against commitment
4. Expired commitments are cleaned up

<details>
<summary>Solution</summary>

```solidity
contract MEVProtectionHook is BaseHook {
    struct SwapCommitment {
        address user;
        PoolId poolId;
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
        uint256 commitBlock;
        bool executed;
    }

    mapping(bytes32 => SwapCommitment) public commitments;

    uint256 public constant COMMITMENT_DELAY = 1; // 1 block delay
    uint256 public constant COMMITMENT_EXPIRY = 20; // Expires after 20 blocks

    event SwapCommitted(
        bytes32 indexed commitmentId,
        address indexed user,
        PoolId indexed poolId,
        uint256 commitBlock
    );

    event SwapExecuted(
        bytes32 indexed commitmentId,
        address indexed user
    );

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    // Step 1: User commits to swap parameters
    function commitSwap(
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params
    ) external returns (bytes32) {
        // Generate commitment ID
        bytes32 commitmentId = keccak256(abi.encodePacked(
            msg.sender,
            key,
            params,
            block.number,
            block.timestamp
        ));

        // Store commitment
        commitments[commitmentId] = SwapCommitment({
            user: msg.sender,
            poolId: key.toId(),
            zeroForOne: params.zeroForOne,
            amountSpecified: params.amountSpecified,
            sqrtPriceLimitX96: params.sqrtPriceLimitX96,
            commitBlock: block.number,
            executed: false
        });

        emit SwapCommitted(commitmentId, msg.sender, key.toId(), block.number);

        return commitmentId;
    }

    // Step 2: Execute swap (next block or later)
    function executeCommittedSwap(
        bytes32 commitmentId,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params
    ) external {
        SwapCommitment storage commitment = commitments[commitmentId];

        // Validate commitment exists
        require(commitment.user != address(0), "No commitment");
        require(commitment.user == msg.sender, "Not your commitment");
        require(!commitment.executed, "Already executed");

        // Validate timing
        uint256 blocksSinceCommit = block.number - commitment.commitBlock;
        require(
            blocksSinceCommit >= COMMITMENT_DELAY,
            "Too soon (MEV protection)"
        );
        require(
            blocksSinceCommit <= COMMITMENT_EXPIRY,
            "Commitment expired"
        );

        // Validate parameters match commitment
        require(key.toId() == commitment.poolId, "Pool mismatch");
        require(params.zeroForOne == commitment.zeroForOne, "Direction mismatch");
        require(
            params.amountSpecified == commitment.amountSpecified,
            "Amount mismatch"
        );
        require(
            params.sqrtPriceLimitX96 == commitment.sqrtPriceLimitX96,
            "Price limit mismatch"
        );

        // Mark as executed
        commitment.executed = true;

        emit SwapExecuted(commitmentId, msg.sender);

        // Execute swap through PoolManager
        // (actual execution logic)
    }

    // Hook to verify execution matches commitment
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external view override returns (bytes4, BeforeSwapDelta, uint24) {
        // Extract commitment ID from hookData
        if (hookData.length >= 32) {
            bytes32 commitmentId = abi.decode(hookData, (bytes32));
            SwapCommitment storage commitment = commitments[commitmentId];

            // If commitment exists, validate it
            if (commitment.user != address(0)) {
                require(commitment.user == sender, "Sender mismatch");
                require(commitment.executed, "Not executed yet");
                // Additional validations...
            }
        }

        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            0
        );
    }

    // Cleanup expired commitments (gas refund)
    function cleanupExpiredCommitments(bytes32[] calldata commitmentIds) external {
        for (uint256 i = 0; i < commitmentIds.length; i++) {
            SwapCommitment storage commitment = commitments[commitmentIds[i]];

            if (commitment.user != address(0) &&
                !commitment.executed &&
                block.number - commitment.commitBlock > COMMITMENT_EXPIRY) {

                delete commitments[commitmentIds[i]];
            }
        }
    }
}
```

### How It Protects Against MEV

1. **Sandwich Attack Prevention**:
   - Attacker can't front-run because they don't know execution block
   - User commits in block N, executes in block N+1 minimum
   - Parameters are locked in at commitment time

2. **Commitment Verification**:
   - Execution must match exact commitment parameters
   - No one can modify swap after commitment

3. **Time Windows**:
   - Minimum delay prevents same-block execution
   - Maximum expiry prevents stale commitments

### Trade-offs

**Pros**:
- Strong MEV protection
- User maintains control
- No additional fees

**Cons**:
- Two transactions required (higher gas)
- Slower execution (~12-24 seconds delay)
- Complexity in UX

</details>

---

## Exercise 6: Implement Helper Function Pattern

### Task

Refactor this repetitive hook to use the helper function pattern.

```solidity
contract RepetitiveHook is BaseHook {
    mapping(address => mapping(PoolId => uint256)) public userPoints;
    mapping(PoolId => uint256) public totalPoints;

    uint256 public constant POINTS_PER_SWAP = 100;
    uint256 public constant POINTS_PER_ADD_LIQ = 200;
    uint256 public constant POINTS_PER_REMOVE_LIQ = 50;

    event PointsAwarded(address indexed user, PoolId indexed poolId, uint256 points);

    function afterSwap(...) internal override returns (bytes4, int128) {
        PoolId poolId = key.toId();
        userPoints[sender][poolId] += POINTS_PER_SWAP;
        totalPoints[poolId] += POINTS_PER_SWAP;
        emit PointsAwarded(sender, poolId, POINTS_PER_SWAP);
        return (BaseHook.afterSwap.selector, 0);
    }

    function afterAddLiquidity(...) internal override returns (bytes4, BalanceDelta) {
        PoolId poolId = key.toId();
        userPoints[sender][poolId] += POINTS_PER_ADD_LIQ;
        totalPoints[poolId] += POINTS_PER_ADD_LIQ;
        emit PointsAwarded(sender, poolId, POINTS_PER_ADD_LIQ);
        return (BaseHook.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function afterRemoveLiquidity(...) internal override returns (bytes4, BalanceDelta) {
        PoolId poolId = key.toId();
        userPoints[sender][poolId] += POINTS_PER_REMOVE_LIQ;
        totalPoints[poolId] += POINTS_PER_REMOVE_LIQ;
        emit PointsAwarded(sender, poolId, POINTS_PER_REMOVE_LIQ);
        return (BaseHook.afterRemoveLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }
}
```

<details>
<summary>Solution</summary>

```solidity
contract RefactoredHook is BaseHook {
    mapping(address => mapping(PoolId => uint256)) public userPoints;
    mapping(PoolId => uint256) public totalPoints;

    uint256 public constant POINTS_PER_SWAP = 100;
    uint256 public constant POINTS_PER_ADD_LIQ = 200;
    uint256 public constant POINTS_PER_REMOVE_LIQ = 50;

    event PointsAwarded(address indexed user, PoolId indexed poolId, uint256 points, string action);

    // HELPER FUNCTION: Eliminates all repetition
    function _awardPoints(
        address user,
        PoolId poolId,
        uint256 points,
        string memory action
    ) internal {
        userPoints[user][poolId] += points;
        totalPoints[poolId] += points;
        emit PointsAwarded(user, poolId, points, action);
    }

    // Now hooks are clean and simple
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        _awardPoints(sender, key.toId(), POINTS_PER_SWAP, "swap");
        return (BaseHook.afterSwap.selector, 0);
    }

    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        _awardPoints(sender, key.toId(), POINTS_PER_ADD_LIQ, "addLiquidity");
        return (BaseHook.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        _awardPoints(sender, key.toId(), POINTS_PER_REMOVE_LIQ, "removeLiquidity");
        return (BaseHook.afterRemoveLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }
}
```

### Benefits Achieved

1. **Reduced Code**: ~60% less code in hook functions
2. **Easier Auditing**: Review logic once instead of 3 times
3. **Consistency**: Guaranteed same behavior
4. **Maintainability**: Fix bugs in one place
5. **Gas Savings**: Shared code path

### Gas Comparison

**Before**: Each hook function = ~95,000 gas
**After**: Each hook function = ~93,000 gas (function call overhead is minimal)

**But more importantly**: Much easier to audit and maintain!

</details>

---

## Challenge Exercise: Build Complete Donation Hook

### Task

Build a production-ready hook that routes 0.1% of swap volume to charitable causes.

### Requirements

1. Users can opt-in to donate (don't force)
2. Multiple charities supported (user chooses)
3. Transparent accounting (events for all donations)
4. Admin can add/remove approved charities
5. Security: Admin uses multisig
6. Gas-optimized
7. Comprehensive tests

### Acceptance Criteria

- [ ] Risk assessment complete (use worksheet)
- [ ] All security patterns implemented
- [ ] Gas optimized (<50k overhead per swap)
- [ ] >90% test coverage
- [ ] Comprehensive documentation

<details>
<summary>Starter Code</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/types/BalanceDelta.sol";

/// @title DonationHook - Routes portion of swaps to charity
/// @author Allan Robinson
/// @notice Users can opt-in to donate 0.1% of their swaps to approved charities
contract DonationHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // TODO: Implement complete donation hook
    // Consider:
    // - Charity registry
    // - User preferences
    // - Donation accounting
    // - Withdrawal mechanism
    // - Events for transparency
    // - Security (CEI pattern, access control)
    // - Gas optimization

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,  // Award points after swap
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // Implement your solution here
}
```

</details>

---

## Additional Practice

### Recommended Activities

1. **Code Review Practice**
   - Review hooks in [v4-periphery/src/hooks](https://github.com/Uniswap/v4-periphery/tree/main/src/hooks)
   - Identify patterns used
   - Look for potential improvements

2. **Security Analysis**
   - Use the security worksheet on real hooks
   - Practice risk scoring
   - Identify vulnerabilities in example code

3. **Gas Optimization**
   - Take existing hooks and optimize them
   - Measure before/after gas usage
   - Document savings

4. **Integration Testing**
   - Write tests that combine multiple hooks
   - Test edge cases
   - Verify invariants hold

---

**Estimated Time**: 6-8 hours for all exercises

**Success Criteria**: Completed all exercises with working, tested code

---

**Allan Robinson**
Security & Design Pattern Exercises - Week 3 - February 2, 2026

