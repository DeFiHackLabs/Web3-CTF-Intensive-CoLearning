//
pragma solidity ^0.8.24;

import "Ethernaut/elevator_poc.sol";
import "forge-std/Test.sol";

contract ElevatorTest is Test {
    ElevatorPoc poc;
    Elevator elevator;

    function setUp() public {
        elevator = new Elevator();
        poc = new ElevatorPoc(address(elevator));
    }

    function test_exploit() public {
        poc.exploit();

        assertTrue(elevator.top());
        assertEq(elevator.floor(), 9);
    }
}