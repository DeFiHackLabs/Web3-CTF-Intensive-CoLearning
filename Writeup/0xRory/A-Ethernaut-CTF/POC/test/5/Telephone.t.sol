// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import { Telephone } from "../../src/5/Telephone.sol";

import { TelephoneAttack } from "../../src/attacks/TelephoneAttack.sol";

contract TelephoneTest is Test {

  Telephone public _telephone;

  TelephoneAttack public _attack;

  address user = makeAddr('Rory');
  function setUp() public {
    _telephone = new Telephone();
    _attack = new TelephoneAttack(address(_telephone));
  }

  function test_Telephone() public {
    vm.startPrank(user);
    // This is a simple contract where you need to call the changeOwner function to change the owner of the contract to the address of your choosing.
    _attack.attack();

    assertEq(_telephone.owner(), user);
    vm.stopPrank();
  }

}