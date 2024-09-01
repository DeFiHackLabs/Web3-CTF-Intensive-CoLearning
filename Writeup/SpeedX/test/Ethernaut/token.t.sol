// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Token} from "Ethernaut/token.sol";
import "forge-std/console.sol";

contract TokenTest is Test {

    function setUp() public {
    }

    function test_Transfer() public {
      uint256 a = 1;
      uint256 b = 2;

      unchecked {
        require(a - b >= 0);
      }
    }
} 