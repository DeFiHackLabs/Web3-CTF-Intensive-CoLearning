---
timezone: America/Los_Angeles
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

### 2024.09.01

#### tx.origin和msg.sender的区别

tx.origin指的是整个交易的发起者，msg.sender指的是当前调用的发起者。例如，一个调用路径A->B->C，在函数C中，msg.sender是B，而tx.origin是A。

tx.origin通常不能用于授权校验（`require(tx.origin == owner)`），这样存在[钓鱼漏洞](https://github.com/AmazingAng/WTF-Solidity/blob/main/S12_TxOrigin/readme.md)。tx.origin可以用于拒绝外部合约调用当前合约，例如：`require(tx.origin == msg.sender)`。

[solidity里的一些全局变量](https://solidity-cn.readthedocs.io/zh/latest/units-and-global-variables.html#block-and-transaction-properties)

#### 整数溢出和下溢

在solidity中，整数类型都有数值范围，例如：`uint256`范围是$[0,2^{256}-1]$，如果超过该范围，这会重新从0开始，小于该范围也是类似。

避免溢出和下溢比较简单的方法就是使用OpenZeppelin的SafeMath，例如

```solidity
using SafeMath for uint;
uint test = 2;
test = test.mul(3);
test = test.add(5);
```

### 2024.09.02

#### delegatecall

`delegatecall`是委托调用的意思，考虑用户`A`通过合约`B`来`delegatecall`合约`C`时，合约`C`的上下文是`B`的，`msg.sender`是`A`的地址，只有逻辑是`C`的。如果函数改变了存储中的变量，真正改变的也是`B`中的存储。为此，合约`B`和合约`C`的变量存储布局必须相同。


### 2024.09.03

#### 删除合约

坎昆升级以前，`selfdestruct(addr)`可以用来删除合约，并将合约剩余ETH转移到指定地址`addr`。

坎昆升级后，`selfdestruct`仅会被用来将合约中的ETH转移到指定地址。如果想要删除合约，则只有当合约的创建和自毁发生在同一笔交易时才能生效。

使用`selfdestruct`转移ETH时，即使目标合约没有receive和fallback函数，也能成功转移


### 2024.09.04

#### 合约private

把合约的一个变量设置private，只是能限制其他合约的访问。但是链上的一切都是公开的，[这里](https://sepolia.etherscan.io/tx/0x9aa9f09a53fa632706cd303324410e87150a1953deef9e2d6d338aa60830ab1f/advanced#statechange)可以看到这个交易中的状态变化，其中包含了private变量


### 2024.09.05

pass

### 2024.09.06

#### 发送ETH

共有三种方法发送ETH，分别是`transfer`, `send`, `call`

##### transfer
- 用法是`接收方地址.transfer(发送ETH数额)`。
- `transfer()`的gas限制是2300，足够用于转账，但对方合约的`fallback()`或`receive()`函数不能实现太复杂的逻辑。
- `transfer()`如果转账失败，**会自动`revert`（回滚交易）。**

##### send
- 用法是`接收方地址.send(发送ETH数额)`。
- `send()`的gas限制是2300，足够用于转账，但对方合约的`fallback()`或`receive()`函数不能实现太复杂的逻辑。
- `send()`如果转账失败，不会`revert`。
- `send()`的返回值是`bool`，代表着转账成功或失败，需要额外代码处理一下。


##### call
- 用法是`接收方地址.call{value: 发送ETH数额}("")`。
- `call()`**没有gas限制**，可以支持对方合约`fallback()`或`receive()`函数实现复杂逻辑。
- `call()`如果转账失败，不会`revert`。
- `call()`的返回值是`(bool, bytes)`，其中bool代表着转账成功或失败，需要额外代码处理一下。

`transfer`失败会自动`revert`，`call`没有gas限制。推荐使用顺序：`call`, `transfer`, `send`

### 2024.09.07

pass

### 2024.09.08

#### 重入攻击

> 总是假设资产的接受方可能是另一个合约, 而不是一个普通的地址. 因此, 他有可能执行了他的payable fallback 之后又“重新进入” 你的合约, 这可能会打乱你的状态或是逻辑.

要避免重入攻击，可以使用[Check-Effects-Interaction](https://docs.soliditylang.org/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern)模式。
即首先检查判断条件满不满足，然后更新当前合约的状态，最后再执行和其他地址的交互。

### 2024.09.09


#### prue和view

- `view`：`view`修饰符用于表示函数仅读取合约状态，不会修改任何状态变量
- `pure`：`pure`修饰符表示函数既不会读取合约状态，也不会修改任何状态变量

有这两个关键字修饰的函数调用时，不会消耗gas

### 2024.09.10

#### 读取合约的存储

solidity的内存布局类似于传统的计算机语言，具体可以参考[这里](https://medium.com/@dariusdev/how-to-read-ethereum-contract-storage-44252c8af925)

#### assembly

可以用接近Ethereum虚拟机的语言，将Solidity语句与内联汇编交错使用。Solidity的内联汇编语言是[Yul](https://docs.soliditylang.org/en/latest/yul.html)

`extcodesize(addr)`用于`addr`的代码长度，如果`addr`是外部地址（非合约），或者实在合约`addr`的构造函数中调用，则返回0

https://ethereum.stackexchange.com/questions/15641/how-does-a-contract-find-out-if-another-address-is-a-contract

https://docs.soliditylang.org/en/latest/assembly.html

### 2024.09.11

pass

### 2024.09.12

#### ERC20

ERC20是以太坊的代币标准，包含了两个事件(`event`)和六个函数(`function`)。

事件

- Transfer: 转账时触发
- Approve: 授权时触发

函数

- `totalSupply()`返回代币总供给
- `balanceOf()`返回账户余额
- `transfer()`转账
- `allowance()`返回授权额度
- `approve()`授权
- `transferFrom()`授权转账

### 2024.09.13

#### delegatecall

用户`A`通过合约`B`来`delegatecall`合约`C`时，合约`C`的上下文是`B`的，`msg.sender`是`A`的地址，只有逻辑是`C`的。如果函数改变了存储中的变量，真正改变的也是`B`中的存储。

如果`B`和`C`的内存布局不一致，也会直接修改`B`的内存。

### 2024.09.14

#### 计算合约的地址

部署一份合约时，合约的地址是可以计算的得到，部署合约有两种方式，`CREATE`和`CREATE2`，两个的计算有些不同

##### CREATE

创建者的地址(通常为部署的钱包地址或者合约地址)和nonce(该地址发送交易的总数,对于合约账户是创建的合约总数,每创建一个合约nonce+1)的哈希。

```
新地址 = hash(创建者地址, nonce)
```

#### CREATE2

`CREATE2`的目的是为了让合约地址独立于未来的事件。不管未来区块链上发生了什么，你都可以把合约部署在事先计算好的地址上。用CREATE2创建的合约地址由4个部分决定：

- `0xFF`：一个常数，避免和`CREATE`冲突
- `CreatorAddress`: 调用`CREATE2`的当前合约（创建合约）地址。
- `salt`：一个创建者指定的`bytes32`类型的值，它的主要目的是用来影响新创建的合约的地址。
- `initcode`: 新合约的初始字节码（合约的`Creation Code`和构造函数的参数）。

```
新地址 = hash("0xFF",创建者地址, salt, initcode)
```

> 合约地址是确定性的，由 `keccack256(address, nonce)` 计算，其中address 是合约的地址（或创建交易的以太坊地址），`nonce `是衍生合约发起的交易数量 （或交易随机数，用于常规交易）。

正因为如此，人们可以将ether发送到一个预先确定的地址（没有私钥），然后在该地址创建一个合约来恢复以太币。 这是一种在不持有私钥的情况下（危险地）存储ether的不直观且有些隐秘的方式。

[Ref1](https://www.wtf.academy/docs/solidity-102/Create2/#create%E5%A6%82%E4%BD%95%E8%AE%A1%E7%AE%97%E5%9C%B0%E5%9D%80), [Ref2](https://learnblockchain.cn/2019/06/10/address-compute/)

<!-- Content_END -->
