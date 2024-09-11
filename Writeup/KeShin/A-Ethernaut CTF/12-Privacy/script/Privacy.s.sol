// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Privacy} from "../src/Privacy.sol";

contract PrivacyScript is Script {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6665543);
    }

    function run() public {
        Privacy privacy = Privacy(0xFc3aef6227C7195a6aBDf6C00C63ef86F17cBAe6);

        vm.startBroadcast();

        privacy.unlock(bytes16(bytes32(0xeea95af5605164566794871e58b38b8c615aef2027d688166268622e1594660d)));
        
        console.log("is locked : ", privacy.locked());
    }
}
