// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Gate} from "src/Gate.sol";

contract Gate_POC is Test {
    Gate _gate;
    function init() private{
        vm.startPrank(address(0x10));
        _gate = new Gate("data1"," data2","data3");
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_Gate_POC() public{
        bytes4 unlock_Selector = bytes4(keccak256("unlock(bytes)"));
        bytes memory data = abi.encode("data3");
        data = abi.encodePacked(unlock_Selector,data);
        _gate.resolve(data);

        console.log("Success:",_gate.isSolved());

    }
        
}