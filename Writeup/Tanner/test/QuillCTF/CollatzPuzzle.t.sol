// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/CollatzPuzzle.sol";

contract CollatzPuzzleTest is Test {
    CollatzPuzzle public collatzPuzzle;
    Exploit public exploit;    
    ExploitProxy public exploitProxy;
    address public deployer;
    address public attacker;
    address public deployedContract;
    bytes public initialization = '0x6020600c60003960206000f36004358060011660105760011c6017565b6003026001015b60805260206080f3';
    bytes public runtime = '0x6004358060011660105760011c6017565b6003026001015b60805260206080f3';

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);

        address newContract;
        bytes memory initializationCode = '0x6020600c60003960206000f36004358060011660105760011c6017565b6003026001015b60805260206080f3';

        vm.startPrank(deployer);
        collatzPuzzle = new CollatzPuzzle();
        vm.stopPrank();

        vm.startPrank(attacker);
        assembly {
            newContract := create(0, add(initializationCode, 0x20), mload(initializationCode))
        }
        console.log(newContract);
        deployedContract = newContract;
        vm.stopPrank();
    }

    function testCollatzPuzzleExploit() public {
        // Exploit
        vm.startPrank(attacker, attacker);
        console.log(deployedContract);
        bool flag = collatzPuzzle.ctf(deployedContract);        
        assertEq(flag, true);
        vm.stopPrank();
    }
}

contract ExploitProxy {
    address public exploit;

    constructor(address _exploit) {
        exploit = _exploit;
    }

    fallback() external {
        exploit.delegatecall(abi.encodeWithSignature("collatzIteration()", ""));
    }
}

contract Exploit {
    function collatzIteration() public pure returns (uint256) {
        for (uint256 n = 1; n < 200; n++) {
            if (n % 2 == 0) {
            return n / 2;
            } else {
            return 3 * n + 1;
            }
        }
    }
}