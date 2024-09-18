// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Elevator} from "../src/Elevator.sol";

contract ElevatorTest is Test {
    uint256 cnt = 0;

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6642457);
    }

    function test_GoTop() public {
        Elevator elevator = Elevator(0x31B585Bad84f40268f67cf11466A966B34685f3a);

        elevator.goTo(1);

        console.log("isTop : ", elevator.top());
    }

    function isLastFloor(uint256 _floor) external returns (bool) {
        if(cnt > 0) {
            return true;
        } else {
            cnt += 1;
            return false;
        }
    }
}
