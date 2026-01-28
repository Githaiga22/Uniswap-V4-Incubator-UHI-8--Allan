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
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";

contract MyFirstHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    MyFirstHook hook;

    function setUp() public {
        // Deploy v4 core contracts
        deployFreshManagerAndRouters();

        // Mine a salt that will produce a hook address with the correct flags
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        (address hookAddress, bytes32 salt) =
            HookMiner.find(address(this), flags, type(MyFirstHook).creationCode, abi.encode(address(manager)));

        // Deploy hook contract
        hook = new MyFirstHook{salt: salt}(IPoolManager(address(manager)));
        require(address(hook) == hookAddress, "Hook address mismatch");

        // Initialize a pool
        (key,) = initPool(
            currency0,
            currency1,
            hook,
            3000, // 0.3% fee
            SQRT_PRICE_1_1 // initial price 1:1
        );

        // Add liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 10 ether,
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );
    }

    function testSwapIncreasesCounter() public {
        // Get initial swap count
        uint256 initialCount = hook.swapCount(key.toId());

        // Perform a swap
        bool zeroForOne = true;
        int256 amountSpecified = -1e18; // negative means exact input
        swap(key, zeroForOne, amountSpecified, ZERO_BYTES);

        // Check that swap count increased
        uint256 finalCount = hook.swapCount(key.toId());
        assertEq(finalCount, initialCount + 1, "Swap count should increase by 1");
    }

    function testMultipleSwaps() public {
        uint256 numSwaps = 5;

        for (uint256 i = 0; i < numSwaps; i++) {
            bool zeroForOne = i % 2 == 0;
            int256 amountSpecified = zeroForOne ? int256(-1e17) : int256(1e17);
            swap(key, zeroForOne, amountSpecified, ZERO_BYTES);
        }

        assertEq(hook.swapCount(key.toId()), numSwaps, "Should count all swaps");
    }
}
