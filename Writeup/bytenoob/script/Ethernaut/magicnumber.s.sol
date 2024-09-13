// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/magicnumber.sol";

contract MagicNumScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        bytes memory bytecode = hex"69602a60005260206000f3600052600a6016f3";
        address solver;
        assembly {
            solver := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        MagicNum magicNum = MagicNum(
            0xFf49b0592C0c41f76758eeA805203f7e5ed5a624
        );
        magicNum.setSolver(solver);
        vm.stopBroadcast();
    }
}
