// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MagicNum} from "../src/MagicNum.sol";

contract MagicNumTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6675909);
    }

    function test_Solver() public {
        MagicNum magicNum = MagicNum(0xCf54eD6Fe33a7D59a120545c72d3f7613379c87A);

        MagicNumSolver magicNumSolver = new MagicNumSolver();

        magicNum.setSolver(address(magicNumSolver));

        address(magicNumSolver).call(abi.encodeWithSignature("whatIsTheMeaningOfLife()"));
    }

}

contract MagicNumSolver {
  constructor() {
    assembly {
      mstore(0, 0x602a60005260206000f3)
      return(0x16, 0x0a)
    }
  }
}