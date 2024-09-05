// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/CollatzPuzzle/CollatzPuzzle.sol";

contract CollatzPuzzleTest is Test {
    CollatzPuzzle public collatzPuzzle;
    address public deployer;

    address public bytecodeAddr;

    function setUp() public {
        deployer = vm.addr(1);

        vm.startPrank(deployer);
        collatzPuzzle = new CollatzPuzzle();

        bytes
            memory bytecode = hex"6020600c60003960206000f36004358060011660105760011c6017565b6003026001015b60805260206080f3";
        address addr;
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(addr != address(0), "Deployment Failed");

        bytecodeAddr = addr;

        vm.stopPrank();
    }

    function testCallCTF() public {
        vm.prank(deployer);
        bool res = collatzPuzzle.ctf(bytecodeAddr);

        assertEq(res, true);
    }
}
