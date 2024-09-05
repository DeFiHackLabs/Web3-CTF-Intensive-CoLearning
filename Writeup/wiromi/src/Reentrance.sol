// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import 'openzeppelin-contracts-06/math/SafeMath.sol';

// Objectives:
// 1. Drain the contract from ETH

contract Reentrance {
  
  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      // @audit-issue Vulnerable to Reentrnacy (Doesn't follow the CEI patterns)
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      // @audit-issue vulnerable to arithmetic underflow (not exploitable)
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}