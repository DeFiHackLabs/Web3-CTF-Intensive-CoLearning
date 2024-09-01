---
timezone: Asia/Shanghai
---
# wangtl175

1. 自我介绍

   wtl 程序员，web3入门玩家，ctf爱好者
2. 你认为你会完成本次残酷学习吗？

   肯定可以

## Notes

<!-- Content_START -->

### 2024.08.29

使用源码构建foundry
```shell
# clone the repository
git clone https://github.com/foundry-rs/foundry.git
cd foundry
# install Forge
cargo install --path ./crates/forge --profile local --force --locked
# install Cast
cargo install --path ./crates/cast --profile local --force --locked
# install Anvil
cargo install --path ./crates/anvil --profile local --force --locked
# install Chisel
cargo install --path ./crates/chisel --profile local --force --locked
```
初始化项目
```shell
forge init ethernaut
```

水龙头，前两个是sepolia，最后一个是holesky
```shell
https://faucets.chain.link/
https://www.alchemy.com/faucets/ethereum-sepolia/
https://cloud.google.com/application/web3/faucet/ethereum/holesky/
```

### 2024.08.30
#### receive和fallback函数

[Ref](https://www.wtf.academy/docs/solidity-102/Fallback/)

这是两个特殊的回调函数，主要在两种情况下被使用
1. 合约接收ETH（指的是直接向合约地址发送ETH，调用合约存在的函数时发送ETH不算）
2. 处理合约中不存在的函数调用

> 一个合约最多有一个receive()函数，声明方式与一般函数不一样，不需要function关键字：receive() external payable { ... }。receive()函数不能有任何的参数，不能返回任何值，必须包含external和payable
> 
> fallback()函数会在调用合约不存在的函数时被触发。可用于接收ETH，也可以用于代理合约proxy contract。fallback()声明时不需要function关键字，必须由external修饰，一般也会用payable修饰，用于接收ETH:fallback() external payable { ... }

```
触发fallback() 还是 receive()?
           接收ETH
              |
         msg.data是空？
            /  \
          是    否
          /      \
receive()存在?   fallback()
        / \
       是  否
      /     \
receive()   fallback()
```


receive()和payable fallback()均不存在的时候，向合约直接发送ETH将会报错（你仍可以通过带有payable的函数向合约发送ETH）


### 2024.08.31

#### 合约的构造函数

构造函数（`constructor`）是一种特殊的函数，每个合约可以定义一个，并在部署合约的时候自动运行一次。注意合约不是必须要定义构造函数的。

在Solidity 0.4.22之前，构造函数不使用`constructor`而是使用与合约名同名的函数作为构造函数。这种写法容易让开发者因书写发生疏漏，让构造函数变成普通函数。

新版本的Solidity使用`constructor`作为构造函数，并且不允许有与合约名同名的函数存在。


<!-- Content_END -->
