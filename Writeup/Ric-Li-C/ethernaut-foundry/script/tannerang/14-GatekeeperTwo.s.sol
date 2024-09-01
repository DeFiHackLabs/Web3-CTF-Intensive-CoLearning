// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/14-GatekeeperTwoAttacker.sol";

contract GatekeeperTwoSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x0C791D1923c738AC8c4ACFD0A60382eE5FF08a23;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE

        /**
         * Gate2:
         *     The "extcodesize(Addr)" refers to the size of the code at address Addr.
         *     Once you call the external function in the address Addr's constructor, "extcodesize(Addr)" would be zero.
         * Gate3:
         *     ^ is a Bitwise XOR. 
         *     Equation (a ^ b = c) equals to (a ^ c = b).
         */
        GatekeeperTwoAttacker gatekeeperTwoAttacker = new GatekeeperTwoAttacker(challengeInstance);

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(14));
    }
}
