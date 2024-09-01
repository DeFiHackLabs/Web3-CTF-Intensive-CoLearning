// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Telephone} from "../src/Telephone.sol";

contract TelephoneTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6611655); 
    }

    function test_ChangeOwner() public {
        Telephone telephone = Telephone(0x6e90A26948a0FB32A4eB98a73e83Fc4Bb8FC0144);

        telephone.changeOwner(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d);

        console.log("owner : ", telephone.owner());
    }

}
