// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { Setup } from "src/voting-vault/Setup.sol";

contract Exploit {
    Setup setup;
    uint256 proposalId;

    constructor(Setup _setup) {
        setup = _setup;
    }

    // Execute this first
    function solvePart1() external {
 
    }

    // Execute this in the next block after solvePart1()
    function solvePart2() external {
 
    }
}