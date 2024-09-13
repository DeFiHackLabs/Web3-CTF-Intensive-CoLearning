// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GatekeeperOne} from "../src/GatekeeperOne.sol";

contract GatekeeperOneTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6665596);
    }

    function test_Enter() public {
        GatekeeperOne gatekeeperOne = GatekeeperOne(0x6c7EF5C8cab660fF20304Ef08C375E889eFa9219);
        // GatekeeperOne gatekeeperOne = new GatekeeperOne();
        
        console.log((gatekeeperOne.entrant()));

        bytes8 key = bytes8(uint64(uint16(uint160(tx.origin))) | (uint64(1) << 32));

        // for(uint256 i = 0;i < 300; i++) {
        //     uint256 gasToUse = 8191 * 3 + i;

        //     (bool success, ) = address(gatekeeperOne).call{gas: gasToUse}(abi.encodeWithSignature("enter(bytes8)", key));
        //     if(success) {
        //         console.log("gas : ", i);
        //         break;
        //     }
        // }

        uint256 gasToUse = 8191 * 3 + 256;
        gatekeeperOne.enter{gas: gasToUse}(key);

        console.log(gatekeeperOne.entrant());
    }

}