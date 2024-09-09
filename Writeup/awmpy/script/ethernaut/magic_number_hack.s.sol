// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {MagicNumberHack} from "ethernaut/magic_number_hack.sol";
import "forge-std/console.sol";

contract MagicNumberHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        MagicNumberHack magicNumberHack = new MagicNumberHack(0xD4aE8EA9644960D32b14Ab2Cbe5f00F224D9d504);
        magicNumberHack.hack();
        vm.stopBroadcast();
    }
}
