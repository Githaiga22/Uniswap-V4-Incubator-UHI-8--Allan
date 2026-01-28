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

