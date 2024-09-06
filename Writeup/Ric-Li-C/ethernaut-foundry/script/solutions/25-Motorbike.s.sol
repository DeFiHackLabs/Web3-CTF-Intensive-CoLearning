// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {King} from "../../challenge-contracts/09-King.sol";

contract MotorbikeSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x3A78EE8462BD2e31133de2B8f1f9CBD973D6eDd6;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");
    address challengeInstanceOnChain =
        0x059Eb4948e7fB39938d5Bb8993A9D2Ce8A443E26; // Change this address into yours after step1 executed.

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        //Motorbike: 0x059Eb4948e7fB39938d5Bb8993A9D2Ce8A443E26
        //Engine: 0x9c4CB32C441F89560997738062645F56FD7a112f

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get King contract;
        King king = King(payable(challengeInstance));

        // Step 2: Call `XXXXX()` function of King contract,
        //         YYYYY;

        // Step 3: Confirm that caller `heroAddress` has successfully obtained ownership of the King contract.
        address heroAddress = vm.addr(heroPrivateKey);
        require(heroAddress == king.owner(), "Owner check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(25));
    }
}
