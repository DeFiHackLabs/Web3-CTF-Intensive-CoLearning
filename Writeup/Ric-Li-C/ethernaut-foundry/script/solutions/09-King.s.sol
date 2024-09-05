// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {King} from "../../challenge-contracts/09-King.sol";

contract KingSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x3049C00639E6dfC269ED1451764a046f7aE500c6;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE Must send at least 0.001 ETH
        address challengeInstance = __createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get King contract;
        King king = King(payable(challengeInstance));

        // Step 2: Call `XXXXX()` function of King contract,

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

        console2.log(successMessage(9));
    }
}
