// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MyFirstHookTest
 * @author Allan Robinson
 * @notice Test suite for MyFirstHook
 * @dev Created: January 27, 2026
 */

import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {MyFirstHook} from "../src/examples/MyFirstHook.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
