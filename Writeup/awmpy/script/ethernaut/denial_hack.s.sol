// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {DenialHack} from "ethernaut/denial_hack.sol";
import "forge-std/console.sol";

contract DenialHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        DenialHack denialHack = new DenialHack(0x67fa9DE6518314B0d3FcB13F94851ded2998F07a);
        denialHack.hack();
        vm.stopBroadcast();
    }
}
