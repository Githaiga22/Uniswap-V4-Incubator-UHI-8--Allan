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

