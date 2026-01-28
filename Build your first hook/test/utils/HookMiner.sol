// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


/**
 * @title HookMiner
 * @author Allan Robinson
 * @notice Utility for mining valid hook addresses via CREATE2
 * @dev Created: January 27, 2026
 */
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

library HookMiner {
    // mask to slice out the bottom 14 bits of the address
    uint160 constant FLAG_MASK = 0x3FFF;

    // Maximum number of iterations to find a salt, avoid infinite loops
    uint256 constant MAX_LOOP = 100_000;
