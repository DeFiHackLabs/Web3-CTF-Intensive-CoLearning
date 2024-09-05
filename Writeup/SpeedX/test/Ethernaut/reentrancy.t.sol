pragma solidity ^0.8.22;

import "Ethernaut/reentrancy_poc.sol";
import {Test} from "forge-std/Test.sol";

contract ReentrancyTest is Test {
    Reentrance reentrance;
    ReentrancyPOC reentrancyPOC;

    function setUp() public {
        reentrance = new Reentrance();
        reentrancyPOC = new ReentrancyPOC(address(reentrance));
    }

    function testExploit() public {
        reentrance.donate{value: 0.001 ether}(address(this));
        assertEq(address(reentrance).balance, 0.001 ether, "Reentrance should have 0.001 ether balance");

        reentrancyPOC.exploit{value: 0.001 ether}();
        
        assertEq(address(reentrance).balance, 0, "Reentrance should have 0 balance");
    }
}