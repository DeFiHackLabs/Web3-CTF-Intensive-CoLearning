// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";

import {Privacy} from "../src/Privacy.sol";

contract PrivacyTest is Test {
    Privacy target;
    PrivacyHacker hackTarget;

    function setUp() public {
        bytes32[3] memory data = [
            keccak256(abi.encodePacked("password1")),
            keccak256(abi.encodePacked("password2")),
            keccak256(abi.encodePacked("password3"))
        ];
        target = new Privacy(data);
        hackTarget = new PrivacyHacker(address(target));
    }

    function test_PrivacyToReceiveEther() public {
        hackTarget.attack("password");
        assert(target.locked() == false);
    }
}

contract PrivacyHacker {
    Privacy target;
    constructor(address _target) {
        target = Privacy(_target);
    }

    function attack(string memory _key) public {
        bytes memory keyBytes = abi.encodePacked(_key);
        bytes16 key = bytes16(keyBytes);
        target.unlock(key);
    }
}
