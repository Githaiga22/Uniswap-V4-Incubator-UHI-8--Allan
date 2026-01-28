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

    function find(
        address deployer,
        uint160 flags,
        bytes memory creationCode,
        bytes memory constructorArgs
    ) external pure returns (address, bytes32) {
        address hookAddress;
        bytes memory creationCodeWithArgs = abi.encodePacked(creationCode, constructorArgs);

        uint256 salt;
        for (salt = 0; salt < MAX_LOOP; salt++) {
            hookAddress = computeAddress(deployer, salt, creationCodeWithArgs);
            if (uint160(hookAddress) & FLAG_MASK == flags) {
                return (hookAddress, bytes32(salt));
            }
        }
        revert("HookMiner: could not find salt");
    }

    function computeAddress(address deployer, uint256 salt, bytes memory creationCode)
        internal
        pure
        returns (address)
    {
        return address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, keccak256(creationCode)))))
        );
    }
}
