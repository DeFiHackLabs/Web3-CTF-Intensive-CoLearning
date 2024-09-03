pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import  "Ethernaut/king_poc.sol";

contract KingTest is Test {
    King king;
    KingPOC kingPOC;

    function setUp() public {
        king = new King();
        kingPOC = new KingPOC(address(king));
    }

    function testExploit() public {
        assertEq(king._king(), address(this));
        assertEq(king.prize(), 0);
        
        // kingPOC.exploit{value: 1 ether}();
        // // assertEq(king.prize(), 1 ether);
        // assertEq(king._king(), address(this));
    }
}