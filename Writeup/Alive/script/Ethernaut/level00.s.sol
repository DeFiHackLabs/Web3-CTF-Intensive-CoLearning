// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {playerScript, Level00} from "../../test/Ethernaut/level00.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        playerScript(Level00(0xb62ac7C6b44761109541c0B9DbFf58064a0F1048));
        vm.stopBroadcast();
    }
}
