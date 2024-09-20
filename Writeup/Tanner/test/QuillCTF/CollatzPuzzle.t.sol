// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/CollatzPuzzle.sol";

contract CollatzPuzzleTest is Test {
    CollatzPuzzle public collatzPuzzle;
    address public deployer;
    address public attacker;
    address public deployedContract;
    bytes public initialization = hex"6020600c60003960206000f3";
    bytes public runtime = hex'6004358060011660105760011c6017565b6003026001015b60805260206080f3';

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);

        vm.startPrank(deployer);
        collatzPuzzle = new CollatzPuzzle();
        vm.stopPrank();

        vm.startPrank(attacker);
        address newContract;
        bytes memory initializationCode = abi.encodePacked(initialization, runtime);
        assembly {
            newContract := create(0, add(initializationCode, 0x20), mload(initializationCode))
        }
        require(newContract != address(0), "Contract deployment failed");
        console.log(newContract);
        deployedContract = newContract;
        vm.stopPrank();
    }

    function testCollatzPuzzleExploit() public {

        // Exploit
        vm.startPrank(attacker, attacker);
        bool flag = collatzPuzzle.ctf(deployedContract);        
        vm.stopPrank();

        // After exploit
        assertEq(flag, true);
    }
}
