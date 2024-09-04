// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/ethernaut/level8/Vault.sol";

contract Level8 is Test {
    Vault level8;

    function setUp() public {
        level8 = new Vault(
            0x7465737400000000000000000000000000000000000000000000000000000000
        );
    }

    function testExploit() public {
        console.log("Vault is :", level8.locked());
        level8.unlock(
            0x7465737400000000000000000000000000000000000000000000000000000000
        );
        console.log("Vault is :", level8.locked());
    }
}
