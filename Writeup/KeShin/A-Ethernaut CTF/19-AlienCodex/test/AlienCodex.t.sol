// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AlienCodex} from "../src/AlienCodex.sol";

contract AlienCodexTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6675995);
    }

    function test_Increment() public {
        AlienCodex alienCodex = AlienCodex(0x9611B23a4cdA4a3c6b2222579aF0442fecE07430);

        console.log("owner : ", alienCodex.owner());
    
        alienCodex.renounceOwnership();

        console.log("owner : ", alienCodex.owner());
        
        alienCodex.transferOwnership(0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d);

        console.log("owner : ", alienCodex.owner());
    }
}
