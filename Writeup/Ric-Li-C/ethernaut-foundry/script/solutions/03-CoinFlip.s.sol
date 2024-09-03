// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {CoinFlipAttacker} from "../../src/03-CoinFlipAttacker.sol";

contract CoinFlipSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xA62fE5344FE62AdC1F356447B669E9E6D10abaaF;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");
    address challengeInstanceOnChain =
        0xE17e4fb48D30f247F749a42Ab35E8465C1ac4732; // Change this address into yours after step1 executed.
    address coinFlipAttackerAddress =
        0x38eddcE71f8d83eBEfe41bEA8EEdb40d8A6e9b93; // Change this address into yours after step1 executed.

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(3));
    }
}
