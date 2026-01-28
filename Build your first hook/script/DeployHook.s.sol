// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title DeployHook
 * @author Allan Robinson
 * @notice Deployment script for Uniswap V4 hooks
 * @dev Created: January 27, 2026
 */

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MyFirstHook} from "../src/examples/MyFirstHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

contract DeployHook is Script {
    function run() external {
        // Replace this with the actual PoolManager address for your network
        // Sepolia: 0x8C4BcBE6b9eF47855f97E675296FA3F6fafa5F1A
        // For local testing, you'll deploy PoolManager first
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Calculate the expected hook address and salt
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        );

