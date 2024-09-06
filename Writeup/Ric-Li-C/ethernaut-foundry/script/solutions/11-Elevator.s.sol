// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Elevator} from "../../challenge-contracts/11-Elevator.sol";

contract ElevatorSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x6DcE47e94Fa22F8E2d8A7FDf538602B1F86aBFd2;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get Elevator contract;
        Elevator elevator = Elevator(payable(challengeInstance));

        // Step 2: Call `XXXXX()` function of Elevator contract,
        //         YYYYY;

        // Step 3: Confirm that caller `heroAddress` has successfully obtained ownership of the Elevator contract.
        address heroAddress = vm.addr(heroPrivateKey);
        require(heroAddress == Elevator.owner(), "Owner check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(11));
    }
}
