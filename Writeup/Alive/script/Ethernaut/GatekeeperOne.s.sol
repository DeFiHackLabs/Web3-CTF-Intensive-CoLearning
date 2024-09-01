// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";
import {GatekeeperOne} from "../../src/Ethernaut/GatekeeperOne.sol";
import {Helper} from "../../test/Ethernaut/GatekeeperOne.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        helper.enter();
        vm.stopBroadcast();
    }
}
