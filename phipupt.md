---
timezone: Asia/Shanghai
---

# phipupt

1. 自我介绍
   接触 web3 挺长时间了，一直浅尝则止，希望借这个机会深入学习下。
2. 你认为你会完成本次残酷学习吗？
   没问题

## Notes

<!-- Content_START -->

### 2024.08.29
The Ethernaut level 0
第一天打卡，内容比较简单，在控制台输入代码即可交互
![截屏2024-08-29 22 51 18](https://github.com/user-attachments/assets/bbf8c784-6562-46e2-9d66-4962a968b368)


### 2024.08.30
The Ethernaut level 1- 获取合约拥有权，并提取余额
只需要先调用 contribute 方法存入一笔资金，再转账任意数量 ether 带合约就可以获得 ownership，进而提取全部余额。
重新温习了 Foundry，写了个合约去调用。但是一直报错，还得再改改。


### 2024.08.31
The Ethernaut level 1

调试了好久，终于成功了。

在 sepolia 重新部署了一个 level01 的 `Fallback` [合约](https://sepolia.etherscan.io/address/0xF6a32a802127712efAAED091Fa946492460Cb703#code)。

写了一个攻击合约去实现所有功能，攻击合约在[这里](Writeup/phipupt/ethernaut/script/Level01.s.sol)。  
具体实现逻辑：
1. 先给攻击合约一定数量的 ether，用于调用 `Fallback` 合约时发送 ether
2. 调用 `attack` 方法，该方法调用 `Fallback` 合约的 `contribute` 方法，存入一笔资金。再直接发送 1 wei 给 `Fallback` 合约，从而获取 `owner` 权限。
3. 最后再调用 `Fallback` 合约的 `withdraw` 方法（此时已经具有 `owner` 权限），成功提取所有资金

![示例代码](Writeup/phipupt/ethernaut/level01.png)


### 2024.09.01
The Ethernaut level 2  

这道题的构造函数是 `Fal1out`，合约名叫 `Fallout`。不仔细检查，完全看不出来区别。

本题想考的知识点应该是：在 Solidity 0.4.22 之前，可以使用与合约同名的函数作为构造函数。从 Solidity 0.4.22 开始，应使用 `constructor` 关键字。

因此，破解这题没什么难度。“构造”函数并没有被执行，合约部署后 `owner` 没有被赋值，为默认值 `0x`。只要调用 `Fal1out` 函数即可获得 `owner` 权限。

下面是使用 Foundry 的 cast 命令去调用智能合约：

（新部署的 `Fallout` 合约，[地址](https://sepolia.etherscan.io/address/0x6c178efb9F79C13f88618F82Dee359025F3C8F71)）

合约部署后调用合约的 `owner` 方法，返回 `0x0000000000000000000000000000000000000000`。
```
cast call \
0x6c178efb9F79C13f88618F82Dee359025F3C8F71  "owner()(address)"  \
--rpc-url sepolia
```

调用 `Fal1out` 函数，获取 `owner` 权限。[交易哈希](https://sepolia.etherscan.io/tx/0xa5733b6b05d9bf1d444e55abda842a3e862df4d4a24c4475a97379d5463157fa)
```
cast send \
0x6c178efb9F79C13f88618F82Dee359025F3C8F71  "Fal1out()()"  \
--value 10000000000 \
--rpc-url sepolia \
--private-key <private key>
```

再次调用上面的 `owner` 方法，返回发送者地址 `0x3EBA4347974cF00b7ba130797e5DbfAB33D8Ef4b`。


### 2024.09.02
The Ethernaut level 3

这个挑战要求在一次投币游戏中通过猜测投币的结果连续正确10次。

为了在连续猜对10次，必须预测 `blockValue`，并在调用 `flip` 函数时提供正确的 `_guess` 参数。

基于以上的分析，可以设计如下步骤来连续正确猜测10次：

1. 部署一个新的合约(`Attacker`)，该合约能够计算并预测 `CoinFlip` 合约的投币结果。
2. 使用该合约调用 `CoinFlip` 合约的 `flip` 函数，这样每次都能提供正确的 `_guess` 参数。
3. 重复调用多次

示例合约在[这里](Writeup/phipupt/ethernaut/script/Level03.s.sol)

链上记录：
- level(`CoinFlip`) 新实例：https://sepolia.etherscan.io/address/0x7ECf6bB565c69ccfac8F5d4b3D785AB78a00F677
- attacker 合约：https://sepolia.etherscan.io/address/0xdce3c80980837bfb66524bc0ccf3d2f5db5ae8ff

![alt text](Writeup/phipupt/ethernaut/level03.png)


### 2024.09.03
The Ethernaut level 4

Ethernaut的第4关要求获得合约的owner权限。

要获得owner权限，需要调用 `changeOwner` 方法，但条件是 `tx.origin != msg.sender`。

这个条件可以通过使用一个中间合约来绕过，通过中间合约去调用目标合约来实现。此时
- `tx.origin` = 发送交易者
- `msg.sender` = 中间合约地址

示例合约在[这里](Writeup/phipupt/ethernaut/script/Level04.s.sol)

链上记录：
- level(`Telephone`) 新实例：0x231014b0FEf1C0AF96189700a43221fACF1DfF7E
- attacker 合约：https://sepolia.etherscan.io/address/0xa380337b31833736daa3a044a41e5fb821d15128
- 可以使用 `cast call` 命令来调用目标合约的 `owner` 函数来获取 `owner` 地址。：
`cast call 0x231014b0FEf1C0AF96189700a43221fACF1DfF7E "owner()(address)" --rpc-url sepolia`


### 2024.09.04
[The Ethernaut level 5](https://ethernaut.openzeppelin.com/level/0x478f3476358Eb166Cb7adE4666d04fbdDB56C407)

这一关要求获得更多的token。

合约看起来没什么问题，但是 solidity 版本用的是是 0.6，没有处理整型的下溢/溢出。

因此，只需要发送大于 20 的值，比如 21，就可以获得 21 个token

直接使用 Foundry 的命令: 

查询余额：

```
cast call <level address> \
"balanceOf(address)(uint256)" <receiver> \
--rpc-url sepolia
```

转账（获取更多token）
```
cast send <level address> \
"transfer(address,uint256)(bool)" <receiver> 21 \
--rpc-url sepolia \
--private-key <deployer private key> 
```

链上记录：
- [level(`Token`) 新实例](https://sepolia.etherscan.io/address/0xC8622C44a00a6d01a0c63390eD54E111ef56282f)
- receiver: 0x5859FdBE15be13b4413F0E5F96Ce27364F6E21C8


### 2024.09.05

[The Ethernaut level 6](https://ethernaut.openzeppelin.com/level/0x73379d8B82Fda494ee59555f333DF7D44483fD58)

这一关要求获得 `Delegation` 合约的 `owner` 权限

要获取 `Delegation` 合约中的 `owner` 权限，关键在于利用 `Delegation` 合约的 `fallback` 函数和 `delegatecall` 的特性。`delegatecall` 会在调用合约的上下文中执行被调用的代码，这意味着它会使用调用合约的存储。

步骤如下：
1. 计算 `Delegate` 合约中 `pwn()` 函数的函数选择器

    `pwn() `函数的选择器是其函数签名的 `keccak256` 哈希的前 4 个字节。

2. 向 `Delegation` 合约发送一个调用，其中：

    `msg.data` 应该是 `pwn()` 函数的选择器。

    可以使用任何数量的 ETH。

3. 这将触发 `Delegation` 合约的 `fallback` 函数，进而使用 `delegatecall` 调用 `Delegate` 合约的 `pwn()` 函数。
4. 由于使用了 `delegatecall`，`pwn()` 函数将在 `Delegation` 合约的上下文中执行，从而将调用者的地址设置为 `Delegation` 合约的 `owner。`

使用 Foundry cast 命令可以更简单：

调用 `Delegation` 合约 `pwn()` 函数
```
cast send <level address> \
"pwn()()" \
--rpc-url sepolia \
--private-key <your private key> 
```

查询当前 `owner`
```
cast call <level address> \
"owner()(address)" \
--rpc-url sepolia
```

链上记录：
- level(`Delegation`) 新实例：[0xA54C5bFcdd15Cb9D38485741C5b304a20E269eB5](https://sepolia.etherscan.io/address/0xA54C5bFcdd15Cb9D38485741C5b304a20E269eB5)
- 获取权限的交易的哈希: [0xa74c34ac10570535f2faa6b86677a3a2c5799783fac5bfe874c3cbbf9d27c3b2](https://sepolia.etherscan.io/tx/0xa74c34ac10570535f2faa6b86677a3a2c5799783fac5bfe874c3cbbf9d27c3b2)


[The Ethernaut level 7](https://ethernaut.openzeppelin.com/level/0xb6c2Ec883DaAac76D8922519E63f875c2ec65575)

这一关的要求是增加 `Forece` 合约的 ether 余额

`Force` 合约没有任何函数，要想向该合约发送 ether，普通转账是不行的。需要使用一些特殊的方法。以下是几种可能的方式：
1. 自毁方法（`selfdestruct`）：这是最常见的强制发送以太币到一个没有接收函数的合约的方法。
2. 预部署合约：使用 `CREATE2` 操作码预先计算出合约的地址，并在合约部署之前向该地址发送 ether。

由于合约不是自己部署，因此采用第一种方式。

示例代码：
```
contract Attacker {
    constructor() {}

    function attack(address receiver) public payable {
        selfdestruct(payable(receiver));
    }

    receive() external payable {}
}
```
完整代码见：[Attacker](ethernaut/script/level07/Attacker.s.sol)

使用Foundry：

调用脚本部署 `Attacker` 合约并且发动 `attack`：
```
forge script script/level07/Attacker.s.sol:CallContractScript --rpc-url sepolia --broadcast

```

查询 ether 余额
```
cast balance 0xd2E4Ba00684F3d61D585ca344ec566e03FA06F47 --rpc-url sepolia
```

链上记录：
- [level(`Force`) 实例](https://sepolia.etherscan.io/address/0xd2E4Ba00684F3d61D585ca344ec566e03FA06F47)
- [自毁并发送 ether 交易](https://sepolia.etherscan.io/tx/0xbc33047553c932bba41adb3e45c83940e7a5c5df4343a08121851c3bee357a7c)



### 2024.09.06

[The Ethernaut level 8](https://ethernaut.openzeppelin.com/level/0xB7257D8Ba61BD1b3Fb7249DCd9330a023a5F3670)

这一关的要求是反转 `Vault` 的 `locked` 状态

`Vault` 合约提供了 `unlock` 函数，只需要提供对应的密码。虽然在合约中密码字段设置为 `private`，无法通过公开的方法访问。但是区块链上的状态变量是公开的，可以通过读取合约的存储插槽读区的值。  
`Vault` 合约中 `password` 状态变量占用插槽1，可以通过 foundry 读取该插槽的值。

示例代码：
```
Vault level = Vault(0x2a27021Aa2ccE6467cDc894E6394152fA8867fB4);

bytes32 password = vm.load(address(level), bytes32(uint256(1)));

level.unlock(password);
```
完整代码见：[这里](ethernaut/script/level08.s.sol)

Foundry 脚本：

调用脚本去读区对应插槽的值：
```
forge script script/level08.s.sol:CallContractScript --rpc-url sepolia --broadcast
```

查询 locked 状态
```
cast call 0x2a27021Aa2ccE6467cDc894E6394152fA8867fB4 \
"locked()(bool)" \
--rpc-url sepolia
```

链上记录：
- [level(`Vault`) 实例](https://sepolia.etherscan.io/address/0x2a27021Aa2ccE6467cDc894E6394152fA8867fB4)
- [调用 `unlock` 函数](https://sepolia.etherscan.io/tx/0xf9600a8004358b0e446be4fb24152ecd4681b3a09ebb010136662ccd6a6185a1)


<!-- Content_END -->
