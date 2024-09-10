// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup, GREY, Safe } from "src/gnosis-unsafe/Setup.sol";
import { ISafe } from "src/gnosis-unsafe/interfaces/ISafe.sol";

contract Exploit {
    Setup setup;

    Safe.Transaction transaction;
    uint8[3] v;
    bytes32[3] r;
    bytes32[3] s;

    constructor(Setup _setup) {
        setup = _setup;
    }

    // Execute this first
    function solvePart1() external {
 
    }
}