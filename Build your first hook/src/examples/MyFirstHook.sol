// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MyFirstHook
 * @author Allan Robinson
 * @notice Basic swap counter hook for Uniswap V4 pools
 * @dev Created: January 27, 2026
 */

import {BaseHook} from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
