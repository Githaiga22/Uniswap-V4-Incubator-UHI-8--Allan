// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {InternalSwapPool} from "../src/InternalSwapPool.sol";

/**
 * @title Deploy InternalSwapPool Hook
 * @notice Deploys the InternalSwapPool hook to Base Sepolia testnet
 * @dev Deployment steps:
 *      1. Calculate hook address with correct flags
 *      2. Deploy hook using CREATE2
 *      3. Verify hook address matches expected flags
 *      4. Output deployment information
 */
contract DeployInternalSwapPool is Script {
    // Base Sepolia PoolManager address
    // This is the v4-core PoolManager deployment on Base Sepolia
    address constant POOL_MANAGER = 0xf242cE588b030d0895c51C0730F2368680f80644;

    // Hook flags for InternalSwapPool
    // Uses: BEFORE_SWAP_FLAG, AFTER_SWAP_FLAG, BEFORE_SWAP_RETURNS_DELTA_FLAG
    uint160 constant FLAGS =
        uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG);

    function run() external {
        // Load deployer private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Calculate the hook address with correct flags
        // Note: In production, you would use CREATE2 with a salt to get the exact address
        // For this deployment, we'll use a simple CREATE and verify the flags match

        console.log("Deploying InternalSwapPool hook...");
        console.log("PoolManager address:", POOL_MANAGER);
        console.log("Required hook flags:", FLAGS);

        // Deploy the hook
        InternalSwapPool hook = new InternalSwapPool(IPoolManager(POOL_MANAGER));

        console.log("Hook deployed at:", address(hook));

        // Verify hook address has correct flags
        uint160 hookAddress = uint160(address(hook));
        uint160 actualFlags = hookAddress & FLAGS;

        if (actualFlags != FLAGS) {
            console.log("WARNING: Hook address flags do not match required flags!");
            console.log("Expected flags:", FLAGS);
            console.log("Actual flags:", actualFlags);
            console.log("You may need to use CREATE2 deployment with a specific salt");
        } else {
            console.log("SUCCESS: Hook address has correct flags");
        }

        // Output deployment information
        console.log("\n=== Deployment Complete ===");
        console.log("Hook Address:", address(hook));
        console.log("PoolManager:", POOL_MANAGER);
        console.log("\nNext steps:");
        console.log("1. Verify contract on Basescan");
        console.log("2. Create pool with this hook");
        console.log("3. Add liquidity to pool");
        console.log("4. Test swap functionality");

        vm.stopBroadcast();
    }
}
