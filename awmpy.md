---
timezone: Asia/Shanghai
---

---

# awmpy

1. 自我介绍
我是一名后端开发工程师，负责公司云靶场的开发工作，熟悉OpenStack与Kubernetes等云计算技术


2. 你认为你会完成本次残酷学习吗？
一定可以

## Notes

<!-- Content_START -->

### 2024.08.29

- Ethernaut

#### 0. Hello Ethernaut

根据提示在浏览器控制台中输入相应的命令即可
需要注意的是：

通过`contract.abi`查看所有可用的方法，再通过`contract.password()`方法获取密码

#### 1. Fallback

查看合约代码后发现receive方法中满足贡献值>0与发送交易的value>0时会将owner设置为sender

首先用小于0.001eth向合约捐献，调用contribute()函数，使我们拥有贡献值

``` bash
await contract.contribute.sendTransaction({ from: player, value: toWei('0.0009')})
```

向合约发送一些eth，触发receive，获取owner

``` bash
await sendTransaction({from: player, to: contract.address, value: toWei('0.000001')})
```

调用withdraw提取余额

``` bash
await contract.owner()
```

#### 2. Fallout

这个合约中构造函数拼写错误导致任何人都可以调用Fal1out函数来获取owner权限

``` bash
await contract.Fal1out()
```

### 2024.08.30

#### 3. Coin Flip

这个挑战的核心点在于eth上的随机数是伪随机数，可直接按照合约中的算法写一遍来获取猜硬币结果

为了保证计算合约和题目的合约是在同一个区块中，因此需要写一个攻击合约来完成此次攻击

被攻击的合约地址需要写成ethernaut生成的合约地址

##### remix

使用remix部署[合约](Writeup/awmpy/remix/ethernaut_coin_flip_hack.sol)，写入ethernaut合约地址作为target

调用10次flip函数，即可过关

##### foundry

在`Writeup/awmpy`目录下执行`forge init`初始化forge项目

将CoinFlip的代码复制到[coin_flip.sol](Writeup/awmpy/src/ethernaut/coin_flip.sol)

在`Writeup/awmpy`目录下新建`.env`文件，在文件中写入`PRIVATE_KEY`环境变量，此变量会在脚本文件中被调用

编写脚本[coin_flip_hack.s.sol](Writeup/awmpy/script/ethernaut/coin_flip_hack.s.sol)，计算guess并调用ethernaut生成的合约，脚本中直接写死合约地址

执行命令进行调用10次后，即可过关

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/coin_flip_hack.s.sol:CoinFlipHackScript -vvvv --broadcast
```

### 2024.08.31

#### 4. Telephone

这个挑战的核心点在于考察`msg.sender`和`tx.origin`的知识，`msg.sender`可能是EOA或合约，`tx.origin`只能是EOA

因此只需要实现以下调用链即可：

``` bash
EOA ==> AttackContract ==> TelephoneContract
```

编写攻击合约[telephone_hack.sol](Writeup/awmpy/src/ethernaut/telephone_hack.sol)
部署攻击合约，部署时指定合约地址为ethernaut生成的合约地址

``` bash
forge create --constructor-args "0xFce4169EcEa2f8FA0A12B0312C96Beb8d8734E76" --rpc-url https://1rpc.io/holesky --private-key $PRIVATE_KEY src/ethernaut/telephone_hack.sol:TelephoneHack
```

编写执行脚本[telephone_hack.s.sol](Writeup/awmpy/script/ethernaut/telephone_hack.s.sol)，其中攻击合约地址为刚部署的攻击合约地址
执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/telephone_hack.s.sol:TelephoneHackScript -vvvv --broadcast
```

#### 5. Token

这个挑战是考察溢出漏洞，Token合约使用的版本是0.6.0，且没有使用SafeMath

此题目给玩家预分配了20枚代币，因此只需要调用合约的`transfer`方法向任意地址转移`21`枚代币就可以触发漏洞

编写攻击脚本[token_hack.s.sol](Writeup/awmpy/script/ethernaut/token_hack.s.sol)，其中实例化Token合约使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/token_hack.s.sol:TokenHackScript -vvvv --broadcast
```

### 2024.09.01

#### 6. Delegation

这个挑战是考察Delegatecall相关知识

`Delegation`合约中实现了一个`fallback`函数，在调用此合约中不存在的函数时，`fallback`函数就会被调用，将原来的calldata传递给它

`Delegate`合约中实现了一个`pwn`方法，将`owner`改为`msg.sender`

而在`Delegatecall`时，`msg.sender`和`msg.value`都不会改变，只需要写脚本调用`Delegation`合约的`pwn`方法即可获得`Delegate`合约的`owner`权限

调用`pwn`方法时需要使用`abi.encodeWithSignature`将函数名转为`function signature`进行调用

编写攻击脚本[delegation_hack.s.sol](Writeup/awmpy/script/ethernaut/delegation_hack.s.sol)，其中实例化Token合约使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/delegation_hack.s.sol:DelegationHackScript -vvvv --broadcast
```

### 2024.09.02

#### 7. Force

考察selfdestruct知识，编写一个合约，自毁时强制把一些eth转给目标合约地址即可

编写攻击脚本[force_hack.s.sol](Writeup/awmpy/script/ethernaut/force_hack.s.sol)，其中转账地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/force_hack.s.sol:ForceHackScript -vvvv --broadcast
```

### 2024.09.03

#### 8. Valut

这是一个猜密码的游戏，需要用到数据存储相关的知识

每个存储槽将使用32个字节（一个字大小）
对于每个变量来说，会根据其类型确定以字节为单位的大小
如果可能的话，少于32字节的多个连续字段将根据以下规则被装入一个存储槽
一个存储槽中的第一个项目以低位对齐的方式存储
值类型只使用存储它们所需的字节数
如果一个值类型在一个存储槽的剩余部分放不下，它将被存储在下一个存储槽
结构和数组数据总是从一个新的存储槽开始，它们的项目根据这些规则被紧密地打包
结构或数组数据后面的项目总是开始一个新的存储槽

`locked`变量存储在slot0，`password`变量因为是32字节类型，无法存放到slot0，只能是在slot1中

在foundry中使用`vm.load`来获取`password`变量内容

编写攻击脚本[vault_hack.s.sol](Writeup/awmpy/script/ethernaut/vault_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/vault_hack.s.sol:VaultHackScript -vvvv --broadcast
```

### 2024.09.04

#### 9. King

这是一个关于DOS攻击的游戏
区块链上较为常见的攻击方式有`消耗过高的GAS`、`External call导致合约不受控`

[WTF-Solidity案例](https://github.com/AmazingAng/WTF-Solidity/blob/main/S09_DoS/readme.md)

[消耗GAS过高的案例](https://solidity-by-example.org/hacks/denial-of-service/)

这个挑战就是要通过`External call`的方式，让其他人无法获得王位

`King`合约中实现了一个`receive`函数，会在转账给这个合约时触发，但转账金额要大于当前King的prize，通过校验后就会将Ether转给当前King，再把`msg.sender`设置为新的king

而这里又没有规定King是EOA还是合约

因此有了以下攻击思路:

1. 编写一个合约，给`King`合约转账触发`King`合约的`receive`函数来使攻击合约成为King
2. 攻击合约中实现一个估计将交易revert掉的`receive`方法让其他人无法再向King转账，以次实现DOS的目的

编写攻击合约[king_hack.sol](Writeup/awmpy/src/ethernaut/king_hack.sol)
编写攻击脚本[king_hack.s.sol](Writeup/awmpy/script/ethernaut/king_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/king_hack.s.sol:KingHackScript -vvvv --broadcast
```

### 2024.09.05

#### 10. Re-entrancy

`Re-entrancy`是一种常见的攻击手法，利用合约external call外部合约时，外部合约故意回call原始合约，让原始合约再次执行external call，直到达成攻击者目的或GAS耗尽，由于攻击者会二次或多次进入目标合约，故被称为重入攻击

在`Re-entrancy`合约的`withdraw`函数中:

1. 先检查提款者的余额是否足够
2. 将`_amount`转入提款者账户
3. 最后修改提款者的余额

攻击手法:

1. 攻击合约调用`donate`函数，存入一些Ether
2. 攻击合约调用`withdraw`函数，提取存入的Ether，让external call触发攻击合约的`receive`函数
3. 攻击合约的`receive`函数再次调用目标合约的`withdraw`函数
4. 重复2-3直到目标合约中所有的Ether都被转走，而修改提款者余额这一步永远不会执行

编写攻击合约[reentrance_hack.sol](Writeup/awmpy/src/ethernaut/reentrance_hack.sol)
编写攻击脚本[reentrance_hack.s.sol](Writeup/awmpy/script/ethernaut/reentrance_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/reentrance_hack.s.sol:ReentranceHackScript -vvvv --broadcast
```

#### 11. Elevator

这一题比较简单，攻击合约中实现一个`isLastFloor`方法，并且第一次被调用时return false，第二次被调用时return true就能将top设置为true

编写攻击合约[elevator_hack.sol](Writeup/awmpy/src/ethernaut/elevator_hack.sol)
编写攻击脚本[elevator_hack.s.sol](Writeup/awmpy/script/ethernaut/elevator_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/elevator_hack.s.sol:ElevatorHackScript -vvvv --broadcast
```

### 2024.09.06

#### 12. Privacy

这一提与Valut十分相似，都是需要通过获取变量的值来通关，核心点还是变量存储的问题，找到密码所在的slot

经过以下推算可以得知`data[2]`存储在`slot5`中
|var                                 |bytes    |slot |
|------------------------------------|---------|-----|
|bool public locked                  |1        |0    |
|uint256 public ID                   |32       |1    |
|uint8 private flattening            |1        |2    |
|uint8 private denomination          |1        |2    |
|uint16 private awkwardness          |2        |2    |
|bytes32[3] private data[0]          |32       |3    |
|bytes32[3] private data[1]          |32       |4    |
|bytes32[3] private data[2]          |32       |5    |

读取slot5值即可通关

编写攻击脚本[privacy_hack.s.sol](Writeup/awmpy/script/ethernaut/privacy_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/privacy_hack.s.sol:PrivacyHackScript -vvvv --broadcast
```

### 2024.09.07

<!-- Content_END -->
