// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PuzzleWallet, PuzzleProxy} from "../src/PuzzleWallet.sol";

contract PuzzleWalletTest is Test {
    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6696996);
    }

    function test_Increment() public {
        PuzzleWallet puzzleWallet = PuzzleWallet(0x2AA22e416868efD1426457205cAFf27314F7E41C);

        PuzzleProxy puzzleProxy = PuzzleProxy(payable(0x2AA22e416868efD1426457205cAFf27314F7E41C));

        address user = 0xA6270E61a6485f649f7E18b6e9eBF4d1d184D69d;

        console.log("maxBalance : ", puzzleWallet.maxBalance());

        console.log("owner : ", puzzleWallet.owner());

        console.log("is user whitelisted : ", puzzleWallet.whitelisted(user));

        console.log("proxy admin : ", puzzleProxy.admin());
    }
}
