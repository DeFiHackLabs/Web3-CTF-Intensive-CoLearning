// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/16-PreservationAttacker.sol";

contract PreservationSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x7ae0655F0Ee1e7752D7C62493CEa1E69A810e2ed;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        PreservationAttacker preservationAttacker = new PreservationAttacker(challengeInstance);
        preservationAttacker.attack();


        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(16));
    }
}
