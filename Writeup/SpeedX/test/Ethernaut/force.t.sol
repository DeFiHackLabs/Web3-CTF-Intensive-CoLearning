pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "Ethernaut/force.sol";

contract ForceTest is Test {
    Force force;
    ForcePOC forcePOC;
    function setUp() public {
        force = new Force();
        new ForcePOC{value: 1}(address(force));
    }

    function test_force() public {
        assertEq(address(force).balance, 1);  
    }
}