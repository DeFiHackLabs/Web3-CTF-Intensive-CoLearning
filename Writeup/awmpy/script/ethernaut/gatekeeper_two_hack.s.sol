// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {GatekeeperTwoHack} from "ethernaut/gatekeeper_two_hack.sol";
import "forge-std/console.sol";

contract GatekeeperTwoHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        GatekeeperTwoHack gatekeeper = new GatekeeperTwoHack(0x0D7453F73bc2B361b36F9dAe07CAaFDEEc23Bf70);
        vm.stopBroadcast();
    }
}
