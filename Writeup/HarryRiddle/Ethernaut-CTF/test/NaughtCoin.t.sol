// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {NaughtCoin} from "../src/NaughtCoin.sol";

contract NaughtCoinTest is Test {
    NaughtCoin target;
    address public user;

    function setUp() public {
        user = makeAddr("user");
        target = new NaughtCoin(user);
    }

    function test_NaughtCoin() public {
        uint256 balance = target.balanceOf(user);
        vm.startPrank(user);
        target.approve(user, balance);
        target.transferFrom(user, address(target), balance);
        assert(target.balanceOf(user) == 0);
    }
}
