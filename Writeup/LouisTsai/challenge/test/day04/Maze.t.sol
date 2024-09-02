// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Challenge} from "../../src/day04/Maze.sol";

contract MazeTest is Test {
    Challenge challenge;
    address m;

    uint256 x = uint8(bytes1(0x46)); //
    uint256 y = uint8(bytes1(0x7a));
    uint256 z = uint8(bytes1(0x75));
    uint256 w = uint8(bytes1(0x5a));

    address xa = vm.addr(x);
    address ya = vm.addr(y);
    address za = vm.addr(z);
    address wa = vm.addr(w);

    function setUp() public {
        challenge = new Challenge();
        deal(address(this), 4 ether);

        etherTransfer(xa, 1 ether);
        etherTransfer(ya, 1 ether);
        etherTransfer(za, 1 ether);
        etherTransfer(wa, 1 ether);

        assertTrue(xa.balance > 0);
        assertTrue(ya.balance > 0);
        assertTrue(za.balance > 0);
        assertTrue(wa.balance > 0);

        m = challenge.target();
    }

    function etherTransfer(address addr, uint256 amount) internal {
        (bool succcess,) = addr.call{value: amount}("");
        require(succcess == true, "Transfer Failed");
    }

    function testExploit() public {}
}
