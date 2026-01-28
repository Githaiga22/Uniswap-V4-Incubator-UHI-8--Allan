// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


/**
 * @title PointsHookTest
 * @author Allan Robinson
 * @notice Test suite for PointsHook
 * @dev Created: January 27, 2026
 */
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PointsHook} from "../src/examples/PointsHook.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {HookMiner} from "./utils/HookMiner.sol";

/**
 * @title PointsHookTest
 * @notice Test suite for the PointsHook contract
 * @dev This demonstrates how to test Uniswap v4 hooks with Foundry
 */
contract PointsHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // The hook we're testing
    PointsHook hook;

    // Test user addresses
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    /**
     * @notice Setup function - runs before each test
     * @dev This is a standard Foundry test pattern:
     *      1. Deploy core contracts (PoolManager, routers)
     *      2. Mine a salt to get correct hook address
     *      3. Deploy the hook
     *      4. Initialize a test pool
     *      5. Add initial liquidity
     */
    function setUp() public {
        // STEP 1: Deploy the Uniswap v4 core contracts
        // This includes PoolManager and test routers
        deployFreshManagerAndRouters();

        // STEP 2: Mine a salt that will produce a hook address with the correct flags
        // The hook address MUST have specific bits set based on which functions it implements
        uint160 flags = uint160(
            Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG
        );

        // HookMiner.find searches for a salt that creates the right address
        // It uses CREATE2 address calculation: keccak256(0xff ++ deployer ++ salt ++ keccak256(bytecode))
        (address hookAddress, bytes32 salt) =
            HookMiner.find(address(this), flags, type(PointsHook).creationCode, abi.encode(address(manager)));

        // STEP 3: Deploy the hook with the mined salt
        // This ensures the deployed address matches our calculated address
        hook = new PointsHook{salt: salt}(IPoolManager(address(manager)));
        require(address(hook) == hookAddress, "Hook address mismatch");

        // Log the hook address for debugging
        console.log("PointsHook deployed at:", address(hook));

        // STEP 4: Initialize a test pool
        // A pool is defined by: currency0, currency1, fee, tickSpacing, and hook
        (key,) = initPool(
            currency0,           // Token A
            currency1,           // Token B
            hook,                // Our points hook
            3000,                // 0.3% fee (3000 basis points)
            SQRT_PRICE_1_1       // Initial price of 1:1
        );

        // STEP 5: Add initial liquidity to the pool
        // Without liquidity, swaps cannot happen!
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,          // Lower tick of our position
                tickUpper: 60,           // Upper tick of our position
                liquidityDelta: 10 ether, // Amount of liquidity to add
                salt: bytes32(0)         // Salt for position ID
            }),
            ZERO_BYTES // No hook data needed
        );
    }

    /**
     * @notice Test that swapping awards points correctly
     * @dev This test verifies:
     *      1. Points are awarded to the swapper
     *      2. The correct number of points is awarded
     *      3. The swap counter is incremented
     */
    function testSwapAwardsPoints() public {
        // Get the pool ID
        PoolId poolId = key.toId();

        // Check initial state - alice should have 0 points
        uint256 initialPoints = hook.getPoints(alice, poolId);
        assertEq(initialPoints, 0, "Alice should start with 0 points");

        // Perform a swap as Alice
        vm.startPrank(alice); // All subsequent calls will be from alice's address

        bool zeroForOne = true;      // Swapping token0 for token1
        int256 amountSpecified = -1e18; // Exact input of 1 token
        swap(key, zeroForOne, amountSpecified, ZERO_BYTES);

        vm.stopPrank(); // Stop impersonating alice

        // Check that points were awarded
        uint256 finalPoints = hook.getPoints(alice, poolId);
        assertEq(finalPoints, hook.POINTS_PER_SWAP(), "Alice should have earned POINTS_PER_SWAP points");

        // Check that swap counter increased
        assertEq(hook.getSwapCount(poolId), 1, "Swap count should be 1");

        // Log results for visibility
        console.log("Alice's points after swap:", finalPoints);
    }

    /**
     * @notice Test that adding liquidity awards points
     * @dev Adding liquidity should award more points than swapping
     */
    function testAddLiquidityAwardsPoints() public {
        PoolId poolId = key.toId();

        // Check initial points
        uint256 initialPoints = hook.getPoints(bob, poolId);
        assertEq(initialPoints, 0, "Bob should start with 0 points");

        // Bob adds liquidity
        vm.startPrank(bob);

        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -120,
                tickUpper: 120,
                liquidityDelta: 5 ether, // Bob adds 5 ETH of liquidity
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );

        vm.stopPrank();

        // Check points awarded
        uint256 finalPoints = hook.getPoints(bob, poolId);
        assertEq(finalPoints, hook.POINTS_PER_LIQUIDITY(), "Bob should have earned POINTS_PER_LIQUIDITY points");

        // Verify it's more than swap points
        assertGt(hook.POINTS_PER_LIQUIDITY(), hook.POINTS_PER_SWAP(), "Liquidity should earn more points than swaps");

        // Check liquidity op counter
        assertEq(hook.getLiquidityOpCount(poolId), 2, "Should have 2 liquidity ops (setUp + this test)");

        console.log("Bob's points after adding liquidity:", finalPoints);
    }

    /**
     * @notice Test multiple swaps accumulate points
     * @dev Points should stack up with each swap
     */
    function testMultipleSwapsAccumulatePoints() public {
        PoolId poolId = key.toId();
        uint256 numSwaps = 5;

        vm.startPrank(alice);

        // Perform multiple swaps
        for (uint256 i = 0; i < numSwaps; i++) {
            // Alternate swap direction to avoid running out of liquidity
            bool zeroForOne = i % 2 == 0;
            int256 amountSpecified = zeroForOne ? int256(-1e17) : int256(1e17);
            swap(key, zeroForOne, amountSpecified, ZERO_BYTES);
        }

        vm.stopPrank();

        // Check accumulated points
        uint256 totalPoints = hook.getPoints(alice, poolId);
        uint256 expectedPoints = hook.POINTS_PER_SWAP() * numSwaps;
        assertEq(totalPoints, expectedPoints, "Points should accumulate correctly");

        // Check swap counter
        assertEq(hook.getSwapCount(poolId), numSwaps, "Should count all swaps");

        console.log("Alice's total points after", numSwaps, "swaps:", totalPoints);
    }

    /**
     * @notice Test that different users have separate point balances
     * @dev Points should be tracked per-user
     */
    function testPointsArePerUser() public {
        PoolId poolId = key.toId();

        // Alice swaps
        vm.prank(alice);
        swap(key, true, -1e18, ZERO_BYTES);

        // Bob swaps
        vm.prank(bob);
        swap(key, false, 1e18, ZERO_BYTES);

        // Check each user's points independently
        uint256 alicePoints = hook.getPoints(alice, poolId);
        uint256 bobPoints = hook.getPoints(bob, poolId);

        assertEq(alicePoints, hook.POINTS_PER_SWAP(), "Alice should have her points");
        assertEq(bobPoints, hook.POINTS_PER_SWAP(), "Bob should have his points");

        console.log("Alice's points:", alicePoints);
        console.log("Bob's points:", bobPoints);
    }

    /**
     * @notice Test combined actions (swap + add liquidity)
     * @dev Shows how points accumulate from different actions
     */
    function testCombinedActions() public {
        PoolId poolId = key.toId();

        vm.startPrank(alice);

        // Alice swaps
        swap(key, true, -1e18, ZERO_BYTES);

        // Alice adds liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 2 ether,
                salt: bytes32(uint256(1)) // Different salt from setUp
            }),
            ZERO_BYTES
        );

        vm.stopPrank();

        // Calculate expected points: swap + liquidity
        uint256 expectedPoints = hook.POINTS_PER_SWAP() + hook.POINTS_PER_LIQUIDITY();
        uint256 actualPoints = hook.getPoints(alice, poolId);

        assertEq(actualPoints, expectedPoints, "Should have points from both actions");

        console.log("Points from swap:", hook.POINTS_PER_SWAP());
        console.log("Points from liquidity:", hook.POINTS_PER_LIQUIDITY());
        console.log("Total points:", actualPoints);
    }
}

/**
 * ============================================
 * TESTING CONCEPTS EXPLAINED
 * ============================================
 *
 * 1. FOUNDRY TEST STRUCTURE
 *    - setUp() runs before each test
 *    - Functions starting with "test" are test cases
 *    - vm.prank(address) makes the next call from that address
 *    - vm.startPrank/stopPrank makes multiple calls from an address
 *
 * 2. ASSERTIONS
 *    - assertEq(a, b, "message") - checks equality
 *    - assertGt(a, b, "message") - checks greater than
 *    - Tests fail if any assertion fails
 *
 * 3. RUNNING TESTS
 *    forge test                    // Run all tests
 *    forge test -vv                // Verbose output
 *    forge test --match-test testSwap  // Run specific test
 *    forge test --gas-report       // Show gas usage
 *
 * 4. DEBUGGING
 *    - Use console.log() to print values
 *    - Use forge test -vvvv for detailed traces
 *    - Check "forge test --help" for more options
 *
 * 5. BEST PRACTICES
 *    - Test one thing per test function
 *    - Use descriptive test names (testWhatShouldHappen)
 *    - Add comments explaining what you're testing
 *    - Test edge cases and failure scenarios
 */
