// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {Handler} from "./Handler.t.sol";

contract Invariant is StdInvariant, Test {
    Handler handler;
    ERC20Mock poolToken;
    ERC20Mock weth;

    int256 constant STARTING_X = 100e18; // Starting PoolToken
    int256 constant STARTING_Y = 50e18; // Starting WETH.

    PoolFactory factory;
    TSwapPool pool;

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        // Jumpstart the pool:: Making Initial balance for the pool.
        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);
        //  Deposit...
        pool.deposit(
            uint256(STARTING_Y),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp)
        );

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
        targetContract(address(handler));
    }

    function invariant_constantProductFormulaStaysTheSame() public {
        assert(handler.actualDeltaX() == handler.expectedDeltaX());
    }
}
