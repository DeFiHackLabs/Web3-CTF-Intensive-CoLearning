// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/ConfidentialHash/ConfidentialHash.sol";

contract ConfidentialHashTest is Test {
    ConfidentialHash public confidentialHash;
    address public deployer;

    function setUp() public {
        deployer = vm.addr(1);

        vm.startPrank(deployer);
        confidentialHash = new ConfidentialHash();

        vm.stopPrank();
    }

    function test_ReadStorageSolot() public view {
        bytes32 aliceHash = vm.load(
            address(confidentialHash),
            bytes32(uint256(4))
        );
        bytes32 bobHash = vm.load(
            address(confidentialHash),
            bytes32(uint256(9))
        );

        bytes32 combinedHash = keccak256(abi.encodePacked(aliceHash, bobHash));
        assertEq(confidentialHash.checkthehash(combinedHash), true);
    }
}
