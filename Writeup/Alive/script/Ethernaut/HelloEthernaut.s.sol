// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {playerScript, HelloEthernaut} from "../../test/Ethernaut/HelloEthernaut.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        playerScript(
            HelloEthernaut(0xb62ac7C6b44761109541c0B9DbFf58064a0F1048)
        );
        vm.stopBroadcast();
    }
}
