// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import { Vault } from "../../src/8/Vault.sol";

contract VaultTest is Test {
  Vault public _vault;
  bytes32 password = keccak256('123');
  function setUp() public {
    _vault = new Vault(password);
  }

  function test_Vault() public {

    bytes32 storedPassword = vm.load(address(_vault), bytes32(uint256(1)));

    assertEq(storedPassword, password, "The stored password does not match!");

  }
}