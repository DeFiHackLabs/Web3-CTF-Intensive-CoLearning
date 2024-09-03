// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/11-ElevatorAttacker.sol";

contract ElevatorSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x6DcE47e94Fa22F8E2d8A7FDf538602B1F86aBFd2;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        ElevatorAttacker elevatorAttacker = new ElevatorAttacker(challengeInstance);
        elevatorAttacker.attack();


        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(11));
    }
}
