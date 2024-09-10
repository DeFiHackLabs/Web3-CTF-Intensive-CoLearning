// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {GatekeeperOneHack} from "ethernaut/gatekeeper_one_hack.sol";
import "forge-std/console.sol";

contract GatekeeperOneHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        GatekeeperOneHack gatekeeper = new GatekeeperOneHack(0xa5be1c4A4535C4c4434E8a6D86a0b8F6b543790F);
        gatekeeper.hack();
        vm.stopBroadcast();
    }
}
