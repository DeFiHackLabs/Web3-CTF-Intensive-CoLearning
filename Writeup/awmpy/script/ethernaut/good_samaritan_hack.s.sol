// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {GoodSamaritanHack} from "ethernaut/good_samaritan_hack.sol";
import "forge-std/console.sol";

contract GoodSamaritanHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        GoodSamaritanHack goodSamaritanHack = new GoodSamaritanHack(0x1745eB597c5C83572B8753714fF3727a1CF857ac);
        goodSamaritanHack.hack();
        vm.stopBroadcast();
    }
}