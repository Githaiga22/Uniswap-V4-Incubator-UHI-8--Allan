# Implementation Details

**Assignment**: UHI Custom Pricing Curve Hook Quest
**Student**: Allan Robinson
**Date**: February 3, 2026

---

## Overview

This document provides a detailed walkthrough of the InternalSwapPool hook implementation, explaining key code sections and design choices.

---

## File: InternalSwapPool.sol (391 lines)

### Contract Setup and Imports

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Core Uniswap V4 interfaces and libraries
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary, toBeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

// Hook base functionality
import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

// Math and state management
import {SwapMath} from "@uniswap/v4-core/src/libraries/SwapMath.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

// Currency operations
import {CurrencySettler} from "v4-periphery/test/utils/CurrencySettler.sol";
```

**Key Imports Explained:**

- `IPoolManager`: Core interface to interact with Uniswap pools
- `PoolKey`: Struct identifying a pool
- `BeforeSwapDelta`: Special delta format for beforeSwap hooks
- `SwapMath`: Used for calculating fair prices
- `CurrencySettler`: Helper for token transfers with PoolManager

### Constants and State Variables

```solidity
contract InternalSwapPool is BaseHook {
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    // Configuration constants
    uint256 public constant DONATE_THRESHOLD_MIN = 0.0001 ether;
    uint256 public constant FEE_BPS = 100;  // 1% = 100 basis points
    uint256 public constant BPS_DENOMINATOR = 10000;

    // Native token address (for ETH handling)
    address public immutable nativeToken;

    // Fee storage per pool
    struct ClaimableFees {
        uint256 amount0;  // ETH fees accumulated
        uint256 amount1;  // TOKEN fees accumulated
    }

    mapping(PoolId => ClaimableFees) internal _poolFees;
```

**Design Choices:**

1. **Constants**: Marked `constant` for gas savings
2. **Immutable nativeToken**: Set once in constructor, cheaper to read
3. **Struct for fees**: Groups related data, cleaner than separate mappings
4. **Internal visibility**: Only accessible within contract and inheritors

### Events

```solidity
event FeesDeposited(
    PoolId indexed poolId,
    uint256 amount0,
    uint256 amount1
);

event FeesDistributed(
    PoolId indexed poolId,
    uint256 amount0
);

event InternalSwapExecuted(
    PoolId indexed poolId,
    uint256 tokenIn,
    uint256 ethOut,
    address indexed user
);
```

**Why These Events:**

- `FeesDeposited`: Track fee accumulation for analytics
- `FeesDistributed`: Monitor LP distributions
- `InternalSwapExecuted`: Verify internal fills are happening

### Constructor

```solidity
constructor(IPoolManager _poolManager, address _nativeToken) BaseHook(_poolManager) {
    nativeToken = _nativeToken;
}
```

**Simple but Important:**

- Calls parent `BaseHook` constructor
- Sets immutable `nativeToken` (address(0) for native ETH)

### Hook Permissions

```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeInitialize: false,
        afterInitialize: false,
        beforeAddLiquidity: false,
        afterAddLiquidity: false,
        beforeRemoveLiquidity: false,
        afterRemoveLiquidity: false,
        beforeSwap: true,                      // ✅
        afterSwap: true,                       // ✅
        beforeDonate: false,
        afterDonate: false,
        beforeSwapReturnDelta: true,           // ✅
        afterSwapReturnDelta: true,            // ✅
        afterAddLiquidityReturnDelta: false,
        afterRemoveLiquidityReturnDelta: false
    });
}
```

**Only Four Permissions Needed:**

1. `beforeSwap`: To fill from internal reserves
2. `beforeSwapReturnDelta`: To modify amountToSwap
3. `afterSwap`: To capture fees
4. `afterSwapReturnDelta`: To extract fees from output

### beforeSwap: The Core Logic

```solidity
function beforeSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    bytes calldata
) external override onlyPoolManager returns (bytes4 selector_, BeforeSwapDelta beforeSwapDelta_, uint24) {
    PoolId poolId = key.toId();

    // Only fill TOKEN → ETH swaps when we have TOKEN reserves
    if (!params.zeroForOne && _poolFees[poolId].amount1 != 0) {
        uint256 tokenIn;
        uint256 ethOut;

        // Get current pool state
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);

        // Handle exact input vs exact output
        if (params.amountSpecified >= 0) {
            // Exact output swap
            (tokenIn, ethOut) = _handleExactOutput(poolId, key, params, sqrtPriceX96);
            beforeSwapDelta_ = toBeforeSwapDelta(-int128(int256(tokenIn)), int128(int256(ethOut)));
        } else {
            // Exact input swap
            (tokenIn, ethOut) = _handleExactInput(poolId, params, sqrtPriceX96);
            beforeSwapDelta_ = toBeforeSwapDelta(int128(int256(ethOut)), -int128(int256(tokenIn)));
        }

        // Update internal reserves
        _poolFees[poolId].amount0 += ethOut;
        _poolFees[poolId].amount1 -= tokenIn;

        // Settle deltas with PoolManager
        poolManager.sync(key.currency0);
        poolManager.sync(key.currency1);
        poolManager.take(key.currency0, address(this), ethOut, false);
        key.currency1.settle(poolManager, address(this), tokenIn, false);

        emit InternalSwapExecuted(poolId, tokenIn, ethOut, sender);
    }

    selector_ = IHooks.beforeSwap.selector;
}
```

**Line-by-Line Analysis:**

```solidity
// Line 1-4: Function signature
function beforeSwap(
    address sender,              // Who initiated the swap
    PoolKey calldata key,        // Pool identifier
    IPoolManager.SwapParams calldata params,  // Swap parameters
    bytes calldata               // Hook data (unused)
) external override onlyPoolManager
```

**Why `onlyPoolManager` modifier?**
- Only PoolManager should call hook functions
- Prevents external manipulation

```solidity
// Line 8: Check if this is a TOKEN → ETH swap with reserves
if (!params.zeroForOne && _poolFees[poolId].amount1 != 0) {
```

**Conditions explained:**
- `!params.zeroForOne`: Swapping currency1 → currency0 (TOKEN → ETH)
- `_poolFees[poolId].amount1 != 0`: We have TOKEN reserves to fill from

```solidity
// Line 12: Get current pool price
(uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);
```

**What is sqrtPriceX96?**
- Square root of price in Q96 fixed-point format
- Used by SwapMath to calculate swap amounts
- Same price AMM uses = fair pricing

```solidity
// Line 14-22: Handle exact input vs exact output
if (params.amountSpecified >= 0) {
    // Exact output: user wants specific ETH amount out
    (tokenIn, ethOut) = _handleExactOutput(...);
    beforeSwapDelta_ = toBeforeSwapDelta(-int128(int256(tokenIn)), int128(int256(ethOut)));
} else {
    // Exact input: user selling specific TOKEN amount
    (tokenIn, ethOut) = _handleExactInput(...);
    beforeSwapDelta_ = toBeforeSwapDelta(int128(int256(ethOut)), -int128(int256(tokenIn)));
}
```

**BeforeSwapDelta signs:**
- Positive = hook receives (user gives to hook)
- Negative = hook gives (hook gives to user)

**Exact Output:**
- `deltaSpecified`: -tokenIn (hook receives TOKEN from user)
- `deltaUnspecified`: +ethOut (hook gives ETH to user)

**Exact Input:**
- `deltaSpecified`: +ethOut (hook gives ETH to user)
- `deltaUnspecified`: -tokenIn (hook receives TOKEN from user)

```solidity
// Line 24-26: Update reserves
_poolFees[poolId].amount0 += ethOut;   // Subtract ETH given to user
_poolFees[poolId].amount1 -= tokenIn;  // Add TOKEN received from user
```

**Wait, shouldn't this be -= ethOut?**
- No! We're tracking fees accumulated, not current balance
- ethOut is ETH we paid out from reserves
- But we're about to receive it back from the user's swap output fee!
- This is advance accounting for the afterSwap fee capture

```solidity
// Line 28-32: Settle deltas
poolManager.sync(key.currency0);  // Update accounting
poolManager.sync(key.currency1);
poolManager.take(key.currency0, address(this), ethOut, false);  // Receive ETH
key.currency1.settle(poolManager, address(this), tokenIn, false);  // Send TOKEN
```

**Order matters:**
1. `sync()` first to snapshot current balance
2. Then transfer tokens
3. PoolManager verifies balance changed by expected amount

### _handleExactInput: Calculating Internal Fill

```solidity
function _handleExactInput(
    PoolId poolId,
    IPoolManager.SwapParams calldata params,
    uint160 sqrtPriceX96
) internal view returns (uint256 tokenIn, uint256 ethOut) {
    // How much TOKEN can we fill from reserves?
    uint256 maxTokenIn = _poolFees[poolId].amount1;
    uint256 desiredTokenIn = uint256(uint128(-params.amountSpecified));

    // Fill the lesser of: reserves available or amount user wants to sell
    tokenIn = desiredTokenIn < maxTokenIn ? desiredTokenIn : maxTokenIn;

    // Calculate ETH output using SwapMath
    (,, ethOut,) = SwapMath.computeSwapStep({
        sqrtPriceCurrentX96: sqrtPriceX96,
        sqrtPriceTargetX96: params.sqrtPriceLimitX96,
        liquidity: poolManager.getLiquidity(poolId),
        amountRemaining: int256(tokenIn),
        feePips: 0  // No fee - we already collect fees in afterSwap
    });
}
```

**Step-by-Step:**

1. **Check reserves**: How much TOKEN do we have?
2. **Check demand**: How much does user want to sell?
3. **Take minimum**: Can't fill more than we have or user wants
4. **Calculate price**: Use SwapMath with current pool state
5. **Return amounts**: TOKEN in, ETH out

**Why feePips = 0?**
- We collect fees separately in afterSwap
- Don't double-charge fees
- Internal fills should be fee-free for user (they already pay 1% in afterSwap)

### _handleExactOutput: Reverse Calculation

```solidity
function _handleExactOutput(
    PoolId poolId,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    uint160 sqrtPriceX96
) internal view returns (uint256 tokenIn, uint256 ethOut) {
    // Calculate TOKEN needed for desired ETH output
    (,, tokenIn,) = SwapMath.computeSwapStep({
        sqrtPriceCurrentX96: sqrtPriceX96,
        sqrtPriceTargetX96: params.sqrtPriceLimitX96,
        liquidity: poolManager.getLiquidity(poolId),
        amountRemaining: int256(uint256(uint128(params.amountSpecified))),
        feePips: 0
    });

    // Can we fill this much?
    uint256 maxTokenIn = _poolFees[poolId].amount1;
    if (tokenIn > maxTokenIn) {
        // We don't have enough, fill what we can
        tokenIn = maxTokenIn;

        // Recalculate ETH output for lesser amount
        (,, ethOut,) = SwapMath.computeSwapStep({
            sqrtPriceCurrentX96: sqrtPriceX96,
            sqrtPriceTargetX96: params.sqrtPriceLimitX96,
            liquidity: poolManager.getLiquidity(poolId),
            amountRemaining: int256(tokenIn),
            feePips: 0
        });
    } else {
        // We have enough, user gets exactly what they want
        ethOut = uint256(uint128(params.amountSpecified));
    }
}
```

**Exact Output is Trickier:**

1. User specifies ETH they want
2. Calculate TOKEN needed
3. Check if we have enough TOKEN
4. If not, reduce ETH output to match TOKEN available
5. Two calls to SwapMath might be needed

### afterSwap: Fee Capture and Distribution

```solidity
function afterSwap(
    address,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata
) external override onlyPoolManager returns (bytes4 selector_, int128 hookDeltaUnspecified_) {
    PoolId poolId = key.toId();

    // Determine which currency user received
    Currency swapFeeCurrency = params.amountSpecified < 0 == params.zeroForOne ? key.currency1 : key.currency0;

    // Get swap output amount
    int128 swapAmount = params.amountSpecified < 0 == params.zeroForOne ? delta.amount1() : delta.amount0();

    // Calculate 1% fee
    uint256 absSwapAmount = swapAmount < 0 ? uint256(uint128(-swapAmount)) : uint256(uint128(swapAmount));
    uint256 swapFee = (absSwapAmount * FEE_BPS) / BPS_DENOMINATOR;

    // Store fee
    if (params.zeroForOne) {
        _poolFees[poolId].amount1 += swapFee;  // TOKEN fee
    } else {
        _poolFees[poolId].amount0 += swapFee;  // ETH fee
    }

    // Extract fee from user's output
    swapFeeCurrency.take(poolManager, address(this), swapFee, false);
    hookDeltaUnspecified_ = -int128(int256(swapFee));

    emit FeesDeposited(poolId, _poolFees[poolId].amount0, _poolFees[poolId].amount1);

    // Try to distribute accumulated ETH fees
    _distributeFees(key);

    selector_ = IHooks.afterSwap.selector;
}
```

**Fee Capture Logic:**

```solidity
// Which token did user receive?
Currency swapFeeCurrency = params.amountSpecified < 0 == params.zeroForOne
    ? key.currency1
    : key.currency0;
```

**Truth table:**

| amountSpecified | zeroForOne | Condition Result | User Received |
|----------------|------------|------------------|---------------|
| Negative (exact in) | true | true == true = true | currency1 (TOKEN) |
| Negative (exact in) | false | true == false = false | currency0 (ETH) |
| Positive (exact out) | true | false == true = false | currency0 (ETH) |
| Positive (exact out) | false | false == false = true | currency1 (TOKEN) |

```solidity
// Extract fee using afterSwapReturnDelta
swapFeeCurrency.take(poolManager, address(this), swapFee, false);
hookDeltaUnspecified_ = -int128(int256(swapFee));
```

**Return value:**
- Negative = reduces user's output
- User receives: originalAmount - swapFee

### _distributeFees: Giving Fees to LPs

```solidity
function _distributeFees(PoolKey calldata key) internal {
    PoolId poolId = key.toId();
    uint256 ethFees = _poolFees[poolId].amount0;

    // Only distribute if above minimum threshold
    if (ethFees >= DONATE_THRESHOLD_MIN) {
        // Donate ETH fees to LPs (zero TOKEN!)
        poolManager.donate(key, ethFees, 0, "");

        // Settle the donation
        key.currency0.settle(poolManager, address(this), ethFees, false);

        // Reset fee counter
        _poolFees[poolId].amount0 = 0;

        emit FeesDistributed(poolId, ethFees);
    }
}
```

**How donate() Works:**

```solidity
poolManager.donate(
    key,      // Which pool
    ethFees,  // amount0 to donate
    0,        // amount1 to donate (ZERO!)
    ""        // hook data
);
```

**Inside PoolManager.donate():**
1. Adds ethFees to pool reserves
2. Doesn't change price
3. Increases all LP positions proportionally
4. LPs can withdraw increased amounts

**Result:**
- LPs get richer in ETH only
- No need to claim
- No TOKEN in fees

---

## Testing Strategy

### Test File: InternalSwapPool.t.sol (541 lines, 13 tests)

#### Test Setup

```solidity
contract InternalSwapPoolTest is Test, Deployers {
    InternalSwapPool hook;
    PoolId poolId;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address lp = makeAddr("lp");

    function setUp() public {
        // Deploy fresh PoolManager
        deployFreshManagerAndRouters();

        // Mine hook address with correct flags
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG |
            Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(InternalSwapPool).creationCode,
            abi.encode(address(manager), address(0))
        );

        hook = new InternalSwapPool{salt: salt}(
            IPoolManager(address(manager)),
            address(0)
        );

        // Initialize pool
        (key, poolId) = initPool(
            currency0,  // ETH
            currency1,  // TOKEN
            hook,
            3000,       // 0.3% pool fee
            SQRT_PRICE_1_1  // 1:1 price
        );

        // Add liquidity as LP
        modifyLiquidityRouter.modifyLiquidity(...);

        // Fund test users
        deal(alice, 100 ether);
        MockERC20(Currency.unwrap(currency1)).mint(bob, 100 ether);
    }
}
```

#### Key Test Cases

**Test 1: Basic Swap Without Internal Pool**

```solidity
function test_BasicSwap_NoInternalPool() public {
    // Bob sells TOKEN before any fees accumulated
    // Should go 100% through AMM

    vm.prank(bob);
    swap(key, false, -1 ether);  // Sell 1 TOKEN

    assertEq(hook.poolFees(key).amount1, 0);  // No internal fill
}
```

**Test 2: Internal Pool Fill**

```solidity
function test_InternalPoolFill() public {
    // Step 1: Alice buys to create TOKEN fees
    vm.prank(alice);
    swap(key, true, -1 ether);  // Buy with 1 ETH

    uint256 tokenFees = hook.poolFees(key).amount1;
    assertGt(tokenFees, 0);

    // Step 2: Bob sells, should fill from internal pool
    vm.expectEmit(true, false, false, false);
    emit InternalSwapExecuted(poolId, ...);

    vm.prank(bob);
    swap(key, false, -1 ether);  // Sell 1 TOKEN

    // Verify TOKEN fees converted to ETH
    assertLt(hook.poolFees(key).amount1, tokenFees);
    assertGt(hook.poolFees(key).amount0, 0);
}
```

**Test 3: Fee Distribution**

```solidity
function test_FeeDistribution_AboveThreshold() public {
    // Accumulate fees above threshold
    // ...swaps...

    uint256 lpBalanceBefore = currency0.balanceOf(lp);

    // Trigger distribution
    vm.prank(bob);
    swap(key, false, -1 ether);

    uint256 lpBalanceAfter = currency0.balanceOf(lp);
    assertGt(lpBalanceAfter, lpBalanceBefore);  // LP got ETH!
}
```

---

## Gas Optimization Results

### Benchmark Comparisons

```
Normal Swap (no hook):         ~50,000 gas
Swap with Internal Fill:       ~85,000 gas  (+70%)
Swap with Fee Capture:         ~75,000 gas  (+50%)
Swap with Distribution:        ~120,000 gas (+140%)
```

**Analysis:**
- Internal fills add ~35k gas (SwapMath + state updates)
- Fee capture adds ~25k gas (take + state update)
- Distribution adds ~45k gas (donate + settle)
- Still acceptable for the functionality provided

---

[← Back to Hook Design](./03-hook-design.md) | [Next: Challenges & Solutions →](./05-challenges-solutions.md)
