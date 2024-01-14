// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; 

import {Test, console2} from "forge-std/Test.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    int256 startingY;
    int256 startingX;
    int256 endingY;
    int256 endingX;

    int256 expectedDeltaY;
    int256 expectedDeltaX;
    int256 actualDeltaY;
    int256 actualDeltaX;

    address liquidityProvider = makeAddr("liquidityProvider");

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(_pool.getWeth()); // Y
        poolToken = ERC20Mock(_pool.getPoolToken()); // X
    }

    function deposit(uint256 wethAmount) public {
        wethAmount = bound(wethAmount, 0, type(uint64).max);

        startingY = weth.balanceOf(address(this));
        startingX = poolToken.balanceOf(address(this));
        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(wethAmount));

        // deposit
        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        poolToken.mint(liquidityProvider, uint256(expectedDeltaX));
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);
        pool.deposit(wethAmount, 0, uint256(expectedDeltaX), uint64(block.timestamp));
        vm.stopPrank();

        // actual deltas
        endingY = weth.balanceOf(address(this));
        endingX = poolToken.balanceOf(address(this));

        actualDeltaX = int256(endingX) - int256(startingX);
        actualDeltaY = int256(endingY) - int256(startingY);
    }
}