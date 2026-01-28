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

