// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {DoubleEntryPointHack} from "ethernaut/double_entry_point_hack.sol";
import {IDoubleEntryPoint} from "ethernaut/double_entry_point_hack.sol";
import {IForta} from "ethernaut/double_entry_point_hack.sol";


contract DoubleEntryPointHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address target = address(0x0F7d8096BE386Df26b0375e651dB0EE237085918);
        address cryptoVault = IDoubleEntryPoint(target).cryptoVault();
        DoubleEntryPointHack doubleEntryPointHack = new DoubleEntryPointHack(cryptoVault);
        address forta = address(IDoubleEntryPoint(target).forta());
        IForta(forta).setDetectionBot(address(doubleEntryPointHack)); // Let setDetectionBot() to trigger delegateTransfer(), then we can call raiseAlert(user);

        vm.stopBroadcast();
    }
}
