// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {AlienCodexHack} from "ethernaut/alien_codex_hack.sol";
import "forge-std/console.sol";

contract AlienCodexHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address target = address(0x9F652f461eB1D988dEc5D3C7C1383839667A9F84);
        AlienCodexHack alienCodexHack = new AlienCodexHack(target);
        alienCodexHack.hack();
        vm.stopBroadcast();
    }
}
