// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/13-GatekeeperOneAttacker.sol";

contract GatekeeperOneSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xb5858B8EDE0030e46C0Ac1aaAedea8Fb71EF423C;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        GatekeeperOneAttacker gatekeeperOneAttacker = new GatekeeperOneAttacker(challengeInstance);
        gatekeeperOneAttacker.attack();


        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(13));
    }
}
