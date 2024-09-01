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
```
await contract.contribute.sendTransaction({ from: player, value: toWei('0.0009')})
```
向合约发送一些eth，触发receive，获取owner
```
await sendTransaction({from: player, to: contract.address, value: toWei('0.000001')})
```
调用withdraw提取余额
```
await contract.owner()
```


#### 2. Fallout

这个合约中构造函数拼写错误导致任何人都可以调用Fal1out函数来获取owner权限
```
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
```
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/coin_flip_hack.s.sol:CoinFlipHackScript -vvvv --broadcast
```

### 2024.08.31

#### 4. Telephone

这个挑战的核心点在于考察`msg.sender`和`tx.origin`的知识，`msg.sender`可能是EOA或合约，`tx.origin`只能是EOA

因此只需要实现以下调用链即可：
```
EOA ==> AttackContract ==> TelephoneContract
```

编写攻击合约[telephone_hack.sol](Writeup/awmpy/src/ethernaut/telephone_hack.sol)
部署攻击合约，部署时指定合约地址为ethernaut生成的合约地址
```
forge create --constructor-args "0xFce4169EcEa2f8FA0A12B0312C96Beb8d8734E76" --rpc-url https://1rpc.io/holesky --private-key $PRIVATE_KEY src/ethernaut/telephone_hack.sol:TelephoneHack
```
编写执行脚本[telephone_hack.s.sol](Writeup/awmpy/script/ethernaut/telephone_hack.s.sol)，其中攻击合约地址为刚部署的攻击合约地址
执行脚本发起攻击
```
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/telephone_hack.s.sol:TelephoneHackScript -vvvv --broadcast
```

#### 5. Token

这个挑战是考察溢出漏洞，Token合约使用的版本是0.6.0，且没有使用SafeMath

此题目给玩家预分配了20枚代币，因此只需要调用合约的`transfer`方法向任意地址转移`21`枚代币就可以触发漏洞

编写攻击脚本[token_hack.s.sol](Writeup/awmpy/script/ethernaut/token_hack.s.sol)，其中实例化Token合约使用ethernaut提供的合约地址

执行脚本发起攻击
```
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
```
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/delegation_hack.s.sol:DelegationHackScript -vvvv --broadcast
```



### 2024.09.02

<!-- Content_END -->
