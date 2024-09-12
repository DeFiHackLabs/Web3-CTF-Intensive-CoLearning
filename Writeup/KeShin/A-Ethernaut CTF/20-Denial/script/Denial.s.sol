// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Denial} from "../src/Denial.sol";
import {DenialTest} from "../test/Denial.t.sol";

contract DenialScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6676069);
    }

    function run() public {
        Denial denial = Denial(payable(0x3a28d7D984dDe34D9815C13Bd8800527779BE2F6));

        vm.startBroadcast();

        DenialTest denialTest = new DenialTest();

        denial.setWithdrawPartner(address(denialTest));
    }
}
