// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/23-DexTwoAttacker.sol";

contract DexTwoSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xf59112032D54862E199626F55cFad4F8a3b0Fce9;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE make sure to change original function into "_createInstance()" for the correct challengeInstance address.
        address challengeInstance = _createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        DexTwoAttacker dexTwoAttacker = new DexTwoAttacker{value: 400}(challengeInstance);
        dexTwoAttacker.attack();

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(23));
    }
}
