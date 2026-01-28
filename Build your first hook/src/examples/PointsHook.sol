// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PointsHook
 * @author Allan Robinson
 * @notice Loyalty rewards hook that awards points for swaps and liquidity provision
 * @dev Created: January 27, 2026
 */

import {BaseHook} from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

contract PointsHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    mapping(address => mapping(PoolId => uint256)) public userPoints;
    mapping(PoolId => uint256) public totalSwaps;
    mapping(PoolId => uint256) public totalLiquidityOps;

    uint256 public constant POINTS_PER_SWAP = 10;
    uint256 public constant POINTS_PER_LIQUIDITY = 50;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        PoolId poolId = key.toId();
        userPoints[sender][poolId] += POINTS_PER_SWAP;
        totalSwaps[poolId]++;

        return (BaseHook.afterSwap.selector, 0);
    }

    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        PoolId poolId = key.toId();
        userPoints[sender][poolId] += POINTS_PER_LIQUIDITY;
        totalLiquidityOps[poolId]++;

        return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function getPoints(address user, PoolId poolId) external view returns (uint256) {
        return userPoints[user][poolId];
    }

    function getSwapCount(PoolId poolId) external view returns (uint256) {
        return totalSwaps[poolId];
    }

    function getLiquidityOpCount(PoolId poolId) external view returns (uint256) {
        return totalLiquidityOps[poolId];
    }
}
