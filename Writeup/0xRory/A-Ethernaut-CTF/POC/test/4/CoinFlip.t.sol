// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import { CoinFlip } from "../../src/4/CoinFlip.sol";
import { CoinFlipAttack } from "../../src/attacks/CoinFlipAttack.sol";

contract CoinFlipTest is Test {
    CoinFlip public _contract;
    CoinFlipAttack public _attack;
    address owner;
    address user = makeAddr('Rory');
    function setUp() public {
        owner = address(this);
        _contract = new CoinFlip();
        _attack = new CoinFlipAttack(address(_contract));
        vm.deal(user, 1 ether);
    }

    function test_CoinFlip() public {
      // This is a coin flipping game where you need to build up your winning streak by guessing the outcome of a coin flip. To complete this level you'll need to use your psychic abilities to guess the correct outcome 10 times in a row.
      vm.startPrank(user);
      for (uint256 i; i < 10; i++) {
            vm.roll(block.number + 1);
            _attack.attack();
      }

      assertEq(_contract.consecutiveWins(), 10);

      vm.stopPrank();
    }
}