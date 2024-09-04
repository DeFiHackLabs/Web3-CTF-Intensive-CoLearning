// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NOTE our goal is to become the owner
contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
