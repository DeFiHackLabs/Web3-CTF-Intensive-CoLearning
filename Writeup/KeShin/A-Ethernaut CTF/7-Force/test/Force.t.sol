// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract ForceTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6622490);
    }

    function test_Transfer() public payable {
        selfdestruct(payable(0x338905CCbAB72014BfCC822a5628615b0e01a611));
    }

    receive() external payable {
        
    }
}
