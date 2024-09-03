// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {TrueXOR} from "../../src/true-xor/true-xor.sol";

interface ITarget {
    function ctf(address) external view returns (bool);
}

contract TrueXORChallenge is Test {
    uint256 slot0 = 12345;
    address targetAddress;

    constructor() {
        address deployedAddress;
        
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("true-xor.sol:TrueXOR")
        );
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        
        require(deployedAddress != address(0), "Deployment failed");

        targetAddress = deployedAddress;
        console.log("Deployed address: %s", deployedAddress);
    }

    function test_ctf() public {
        vm.prank(tx.origin);
        ITarget(targetAddress).ctf(address(this));
    }

    function giveBool() public returns (bool) {
        uint gas = gasleft();
        uint tmp = slot0;
        tmp; // silence warning
        return (gas - gasleft()) >= 2000;
    }
}