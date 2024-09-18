// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {ElevatorHack} from "ethernaut/elevator_hack.sol";
import "forge-std/console.sol";

contract ElevatorHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        ElevatorHack elevatorHack = new ElevatorHack(0x4ef30E4637CCd1ac2E05A98e83eBb0A6068ade3D);
        elevatorHack.hack();
        vm.stopBroadcast();
    }
}
