// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/26-DoubleEntryPointAttacker.sol";

contract DoubleEntryPointSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x34bD06F195756635a10A7018568E033bC15F3FB5;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = _createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        DoubleEntryPointAttacker doubleEntryPointAttacker = new DoubleEntryPointAttacker(challengeInstance);
        address forta = address(IDoubleEntryPoint(challengeInstance).forta());
        IForta(forta).setDetectionBot(address(doubleEntryPointAttacker)); // Let setDetectionBot() to trigger delegateTransfer(), then we can call raiseAlert(user);

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(26));
    }
}
