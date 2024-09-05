// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import { Force } from "../../src/7/Force.sol";
import { ForceAttack } from "../../src/attacks/ForceAttack.sol";


contract ForceTest is Test {
  Force public _force;
  ForceAttack public _forceAttack;

  address user = makeAddr('Rory');

  function setUp() public {
    _force = new Force();
    _forceAttack = new ForceAttack();
    vm.deal(address(_forceAttack), 1 ether);
  }

  function test_Force() public {

    _forceAttack.attack{value: 0.1 ether}(payable(address(_force)));
    console.log("Balance_force: ", address(_force).balance);
    console.log("Balance_user: ", address(user).balance);
    console.log("Balance_attack: ", address(_forceAttack).balance);
    assertTrue(address(_force).balance == 1.1 ether);

  }
}
