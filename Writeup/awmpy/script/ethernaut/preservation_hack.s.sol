// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PreservationHack} from "ethernaut/preservation_hack.sol";
import "forge-std/console.sol";

contract PreservationHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        PreservationHack preservation = new PreservationHack(0x7592Bb9160eaB86347cE12F72b9AE97bC7e85f7D);
        preservation.hack();
        vm.stopBroadcast();
    }
}
