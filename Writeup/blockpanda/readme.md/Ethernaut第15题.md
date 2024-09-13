### 第十五题 Naught Coin
### 题目
NaughtCoin 是一种 ERC20 代币，而且您已经持有这些代币。问题是您只能在 10 年之后才能转移它们。您能尝试将它们转移到另一个地址，以便您可以自由使用它们吗？通过将您的代币余额变为 0 来完成此关卡。
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
//继承自ERC20合约
contract NaughtCoin is ERC20 {
    // string public constant name = 'NaughtCoin';
    // string public constant symbol = '0x0';
    // uint public constant decimals = 18;
    //timeLock: 锁定时间，设置为当前时间加上 10 年。
    uint256 public timeLock = block.timestamp + 10 * 365 days;
    uint256 public INITIAL_SUPPLY;
    address public player;
    //ERC20("NaughtCoin", "0x0"): 调用父合约 ERC20 的构造函数，设置代币名称为 “NaughtCoin”，符号为 “0x0”。
    constructor(address _player) ERC20("NaughtCoin", "0x0") {
        player = _player;
        //设置初始供应量为 100 万个代币，考虑到代币的小数位数。
        INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals()));
        // _totalSupply = INITIAL_SUPPLY;
        // _balances[player] = INITIAL_SUPPLY;
        //铸造初始供应量的代币，并分配给 player
        _mint(player, INITIAL_SUPPLY);
        // 触发转账事件，从地址 0 转移到 player
        emit Transfer(address(0), player, INITIAL_SUPPLY);
    }
    //重写 ERC20 合约中的 transfer 函数。使用 lockTokens 修饰符来限制转账行为。
    function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
        //调用父合约的 transfer 函数。
        super.transfer(_to, _value);
    }

    // Prevent the initial owner from transferring tokens until the timelock has passed
    modifier lockTokens() {
        if (msg.sender == player) {
            require(block.timestamp > timeLock);
            _;
        } else {
            _;
        }
    }
}
```
### 解题思路&过程
1. localTokens只限制了transfer函数的msg.sender不能为player,但在限制erc20标准中还有另一个转账函数transferFrom
2. 账前需要先使用approve函数授权，然后再调用此函数转账即可
3.
```solidity //secondaddr是另外一个账户地址
secondaddr='0xCB3D2F536f533869f726F0A3eA2907CAA67DDca1'
totalvalue='1000000000000000000000000'//给自己授权
await contract.approve(player,totalvalue)
await contract.transferFrom(player,secondaddr,totalvalue)
```
4. 提交
