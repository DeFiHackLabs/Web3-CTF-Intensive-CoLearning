// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PrivacyTest} from "../test/Privacy.t.sol";

contract PrivacyScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        PrivacyTest privacyTest = new PrivacyTest();

        privacyTest.test_Unlock();
    }
}
