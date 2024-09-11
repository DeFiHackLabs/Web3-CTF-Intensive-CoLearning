// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup } from "src/simple-amm-vault/Setup.sol";

contract Exploit {
    Setup setup;

    constructor(Setup _setup) {
        setup = _setup;
    }

    function solve() external {
 
    }

    function onFlashLoan(uint256 svAmount, bytes calldata) external {
 
    }
}