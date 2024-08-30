// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract factory {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not owner");
        _;
    }

    modifier isUserBlacklisted(address user) {
        require(_blacklist[user] == false, "user is blacklisted");
        _;
    }

    mapping(address => uint256) public _balances;
    mapping(address => bool) public _blacklist;

    function blacklistuser(address user) public onlyOwner {
        uint256 balance = _balances[user];
        require(balance != 0, "user does not exist");
        _blacklist[user] = true;
    }

    function whitelistuser(address user) public onlyOwner {
        bool blacklist = _blacklist[user];
        require(blacklist == true, "user is not blacklisted");
        _blacklist[user] = false;
    }

    function supply(address _user, uint256 _amount) public {
        require(_user == msg.sender, "unauthorized");
        require(_balances[_user] == 0, "already exists");
        require(_amount > 0, "invalid amount");
        _balances[_user] += _amount;
        _blacklist[_user] = false;
    }

    function checkbalance(address _user) public view returns (uint256) {
        return _balances[_user];
    }

    function transfer(address _from, address _to, uint256 _amount) public isUserBlacklisted(_from) {
        uint256 frombalance = _balances[_from];
        uint256 tobalance = _balances[_to];
        require(_from == msg.sender, "unauthorized");
        require(frombalance != 0, "no balance");
        require(tobalance != 0, "unknown user");
        require(_amount <= frombalance, "not enough balance");

        _balances[_from] = frombalance - _amount;
        _balances[_to] = tobalance + _amount;
    }

    function remove(address _from, uint256 _amount) public isUserBlacklisted(_from) {
        require(_from == msg.sender, "unauthorized");
        uint256 _accountbalance = _balances[_from];
        require(_amount <= _accountbalance, "not enough balance");

        if (_amount == _accountbalance) {
            delete _balances[_from];
            delete _blacklist[_from];
        } else {
            _accountbalance -= _amount;
            _balances[_from] = _accountbalance;
        }
    }
}
