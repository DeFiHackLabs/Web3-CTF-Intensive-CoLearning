// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {SwitchHack} from "ethernaut/switch_hack.sol";
import "forge-std/console.sol";

contract SwitchHackScript is Script {

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        SwitchHack switchHack = new SwitchHack(0xc1d4013450C3D039F8dD2B1cA7b62C704d5a4Cde);
        switchHack.hack();
        vm.stopBroadcast();
    }
}
