// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Setup } from "../src/escrow/Setup.sol";
import { EscrowFactory } from "../src/escrow/EscrowFactory.sol";
import { DualAssetEscrow } from "../src/escrow/DualAssetEscrow.sol";
import { GREY } from "../src/escrow/lib/GREY.sol";

contract EscrowTest is Test {
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

    function test_escrow() public checkSolvedByPlayer {
        GREY grey = setup.grey();
        DualAssetEscrow escrow = DualAssetEscrow(setup.escrow());
        EscrowFactory factory = setup.factory();

        vm.expectRevert("NOT_MINTED");
        escrow.owner();

        (uint256 escrowId, ) = factory.deployEscrow(
            0, 
            abi.encodePacked(address(grey), bytes19(""))
        );
        assertEq(escrow.escrowId(), escrowId);
        assertEq(escrow.owner(), player);

        escrow.withdraw(true, grey.balanceOf(address(escrow)));
    }
}
