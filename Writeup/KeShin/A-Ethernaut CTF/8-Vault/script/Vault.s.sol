// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";

contract VaultScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6630913);
    }

    function run() public {
        vm.startBroadcast();
        
        Vault vault = Vault(0x3a87403815790c542092236e4E7Fa9881274E523);

        vault.unlock(bytes32(0x412076657279207374726f6e67207365637265742070617373776f7264203a29));

        console.log("is locked : ", vm.toString(vault.locked()));
    }
}
