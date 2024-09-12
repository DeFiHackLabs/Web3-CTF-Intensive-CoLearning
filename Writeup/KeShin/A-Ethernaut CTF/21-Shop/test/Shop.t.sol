// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Shop} from "../src/Shop.sol";

contract ShopTest is Test {
    bool flag = false;

    function setUp() public {
        vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com", 6676195);
    }

    function price() external view returns (uint256) {
        Shop shop = Shop(0x7aeB78c0715654157169EC37A004D828c4bcBEC5);
        bool isSold = shop.isSold();
        if(!isSold) {
            return 200;
        } else {
            return 1;
        }
    }

    function test_Buy() public {
        Shop shop = Shop(0x7aeB78c0715654157169EC37A004D828c4bcBEC5);

        shop.buy();

        console.log(shop.isSold());

        console.log(shop.price());
    }

}
