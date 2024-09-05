// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Objectives:
// 1. Unlock the vault

contract Vault {
  bool public locked;
  bytes32 private password;

  constructor(bytes32 _password) {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
}