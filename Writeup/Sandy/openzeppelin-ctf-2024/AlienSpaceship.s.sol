// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "forge-ctf/CTFSolver.sol";
import "src/AlienSpaceship.sol";
import {Challenge} from "src/Challenge.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";

contract Exploit {
    Challenge private immutable CHALLENGE;
    AlienSpaceship public alienSpaceship;
    ExtraAccount public extraAccount;

