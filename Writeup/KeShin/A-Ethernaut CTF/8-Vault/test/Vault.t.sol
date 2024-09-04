// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

contract VaultTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6630913);
    }

    function test_GetPassword() public {
        Vault vault = Vault(0x3a87403815790c542092236e4E7Fa9881274E523);

        bytes32 password = vm.load(address(vault), bytes32(uint256(1)));

        console.log("Password : ", vm.toString(password));

        vault.unlock(password);

        console.log("is locked : ", vm.toString(vault.locked()));
    }

}
