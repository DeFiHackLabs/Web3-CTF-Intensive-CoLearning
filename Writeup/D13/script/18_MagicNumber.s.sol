// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/18_MagicNumber.sol";

contract ExploitScript is Script {
    MagicNum level18 = MagicNum(payable(0xcE193Bfa1364E0A5A58B4e920D56203C5f62E7Ba));
    
    function run() external {
        vm.startBroadcast();
        console.log(payable(0x03bca201595777C0B67DC5970c4356DaD484A1d6));
        level18.setSolver(address(new MagicNumAttack()));
        vm.stopBroadcast();
    }
}

contract MagicNumAttack {
  
  constructor() {
    assembly {
      mstore(0, 0x602a60005260206000f3)
      return(22, 0x0a)
    }
  }
}