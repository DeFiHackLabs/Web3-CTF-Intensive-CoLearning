// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DetectionBot} from "../test/DoubleEntryPoint.t.sol";
import {DoubleEntryPoint, IDetectionBot, IForta, Forta, LegacyToken, CryptoVault} from "../src/DoubleEntryPoint.sol";

contract DoubleEntryPointScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6701093);
    }

    function run() public {
        DoubleEntryPoint doubleEntryPoint = DoubleEntryPoint(0x8b3aD35dd009FB4a298F5cce7977f58c0F506711);
        
        Forta forta = doubleEntryPoint.forta();

        vm.startBroadcast();

        DetectionBot detectionBot = new DetectionBot();

        forta.setDetectionBot(address(detectionBot));
    }
}
