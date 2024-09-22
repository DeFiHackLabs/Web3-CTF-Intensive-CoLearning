// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Impl is UUPSUpgradeable, Ownable {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public withdrawals;
    mapping(address => bool) public whitelistedUsers;

    constructor() Ownable(msg.sender) {}

    function initialize(address owner) public payable {
        require(owner == address(0), "!initialize");
        owner = _msgSender();
        require(msg.value >= 0.1 ether, "!ether");
        balances[_msgSender()] += msg.value;
        _transferOwnership(owner);
    }

    function deposit() public payable {
        require(whitelistedUsers[_msgSender()], "!whitelisted");
        balances[_msgSender()] += msg.value;
    }

    function withdraw(uint256 amount) public {
        address sender = _msgSender();
        require(whitelistedUsers[sender], "!whitelisted");
        require(balances[sender] >= amount, "!balance");
        balances[sender] -= amount;
        payable(sender).transfer(amount);
        withdrawals[sender] += amount;
    }

    function getBalance() public view returns (uint256) {
        return balances[_msgSender()];
    }

    function getWithdrawals() public view returns (uint256) {
        return withdrawals[_msgSender()];
    }

    function whitelistUser(address user) public onlyOwner {
        whitelistedUsers[user] = true;
    }

    function removeUser(address user) public onlyOwner {
        whitelistedUsers[user] = false;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {
        require(withdrawals[_msgSender()] > 1, "!withdraw");
        require(whitelistedUsers[_msgSender()], "!whitelisted");
    }
}