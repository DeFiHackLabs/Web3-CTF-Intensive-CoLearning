---
timezone: Asia/Shanghai
---

> 请在上边的 timezone 添加你的当地时区，这会有助于你的打卡状态的自动化更新，如果没有添加，默认为北京时间 UTC+8 时区
> 时区请参考以下列表，请移除 # 以后的内容

---

# lianshus

1. web3 learner && 小菜鸟
2. 很难说啊，希望能坚持下来

## Notes
<!-- Content_START -->

### 2024.08.29

学习內容:

开始第一天的学习，主要是对 Foundry 工具的使用以及 Solidity 语法的复习

完成了 ethernaut fallback ，在remix上很好交互

在 foundry 上测试有点不太熟练，其中关于**切换调用者**的作弊码不太熟练

（这里个人概括对于作弊码就是非 Solidity 以及其他外部环境的一些操作）

首先是什么是 vm.prank

其次是一直以为切换没成功，实际是账户没有钱，很神奇还是，先转账了才能继续测试

其次关于这个 fallback 与 receive 的复习，之前记了语法，现在实际应用了一把，还是比光看视频和文档让人印象深刻

有一点忙，今天只简单看了A系列一题，后续题目等和 erthernaut交互后继续

POC -- Fallback : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/Fallback.md

### 2024.08.30

补充打卡：

学习內容:

这两天做了A系列2题

1. Fallout: 感觉很简单的一道题，可以直接调用函数修改合约 owner，但是没看懂那个真实实例的讲解

2. CoinFlip: 链上没有随机数的体验？区块信息一切都是透明的，函数调用就在同一个区块里，对作弊码有了更深的体验，在同一个函数调用中也能改变区块号，太牛了，所以作弊码是高于所有函数的？

   ```solidity
       function test_attack() public {
           console.log("before",coin.consecutiveWins());
   
           for(uint256 i=0;i<10;i++){
               attackContract.attack();
               uint256 nextblock = block.number+1;
               vm.roll(nextblock);
           }
           console.log("after",coin.consecutiveWins());
       }
   ```

POC -- CoinFlip : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/CoinFlip.md

### 2024.08.31

尖锐爆铭，昨天做了题，但没交pr，应该是忙着下班以为自己提了

学习內容:

这两天做了A系列3题

1. Fallout: 感觉很简单的一道题，可以直接调用函数修改合约 owner，但是没看懂那个真实实例的讲解

2. CoinFlip: 链上没有随机数的体验？区块信息一切都是透明的，函数调用就在同一个区块里，对作弊码有了更深的体验，在同一个函数调用中也能改变区块号，太牛了，所以作弊码是高于所有函数的？

   ```solidity
       function test_attack() public {
           console.log("before",coin.consecutiveWins());
   
           for(uint256 i=0;i<10;i++){
               attackContract.attack();
               uint256 nextblock = block.number+1;
               vm.roll(nextblock);
           }
           console.log("after",coin.consecutiveWins());
       }
   ```

3. telephone: 之前就记得合约变量去调用合约函数他的tx.origin是不同的，成功的解题，

   但是在 attack 方法中去调用发现，发现 msg.sender 和 tx.origin 都是一个，当时很纠结，没看懂怎么成功的，后面通过去看讲解，有了跟更入的理解

   首先：1. 原理是对所有交易来说，tx.origin 一定是用户地址，但如果有中继合约，没有直接与最终合约交互， 那 msg.sender 就会是合约地址

   2. 我的误区在于，我是在 attack 函数中测试 tx.origin 和 msg.sender 的，对于这个函数来说，我作为用户是直接去用的，而changeOwner函数才是我最终通过合约变量去调用的函数，所以，只对于 changeOwner 函数来说，我的 msg.owner 是 attack合约的地址，这也导致了两个不一样，通过了

      ```solidity
      // attack
          function attack() public returns (address) {
              telephone.changeOwner(tx.origin);
              return tx.origin;
          }
          
      // changeOwner
          function changeOwner(address _owner) public {
              if (tx.origin != msg.sender) {
                  owner = _owner;
              }
          }
      ```

POC -- Telephone: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/Telephone.md

### 2024.09.01

学习內容:

这两天做了A系列1题

Token: 看到版本0.6就感觉是经典的uint256 整数溢出问题，但是记得以前做题是时间锁，哪个是上溢问题，这次也以为是这样，结果是下溢问题

总结了规律：

1. 加法上溢，超出最大范围变成最小值
2. 减法下溢，超出最小范围就变成最大值

POC -- Token: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/Teoken.md

### 2024.09.02

学习內容:

做了A系列1题

delegatecall : 进度非常慢，非常疑惑的一天

还是没怎么搞清楚，对于 delegation 来说，当调用不存在的函数时，会触发fallback，从而导致 使用 delegate 实例去 delegate call 函数，delegate call的原理，应该时使用 delegate 的代码修改 delegation 的状态，为什么没有更改回来呢？

以及，修复一个昨天的误区：用户转账超过余额给别人，但下溢后，导致自己的余额反而增加

POC -- Delegation: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/Delegation.md

### 2024.09.03

学习內容:

做了A系列1题

1. 昨天关于delegation疑问得到解答，原来只是对delegatecall的应用问题，纯属想太多，就是改delegation的owner
2. 今天成功把wsl环境改好了，把token,force,delegation的poc写好了
3. 关于 vault ，还是很神奇，深入体会到链上数据透明的性质，private的变量也能获取到

POC -- Valut : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/Valut.md

### 2024.09.04

学习內容:

做了A系列2题

1. 完成 king poc,这里用的是合约接收转账后可以触发fallback和receive的特性，在这个函数中抛出异常就可以禁止更新king,这样别人转账后，king永远不变
2. 关于重入，逻辑是通了，复现有点问题

POC -- king : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/King.md

### 2024.09.05

学习內容:

做了A系列2题

1. 整理了之前题目的 poc
2. 关于重入,复现成功，找出了两个坑，继承的时候同时继承了receive函数，导致转账后直接进 receive而不进fallback
3. 关于电梯，虽然通过接口确保了外部合约一定有指定函数，但是函数逻辑可以由外部定义，在调用相同参数的情况下可以返回不同的值，还是很神奇
4. 整理到了 9.1 号，后续的不能光测试了，还要写部署交互的了，继续学习foundry

POC -- Reentrance : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/Reentrance.md

### 2024.09.06

学习內容:

做了A系列1题

1. 今天做的privacy也是关于存储的题，准备明天好好看一下soldiity 的存储部分，然后好好记录
2. 学习了使用 foudry 和链上程序的交互，包括数据的查看，函数的调用

POC -- : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/





### 2024.09.07

学习內容:

做了A系列1题

今天主要是关于 合约中状态变量存储的学习，大概理解了 storage与插槽，具体内容，让我整理出一篇 blog吧

先大概梳理一下重点：

1. 合约状态变量转为16进制后相当于存储在一个 2 的256次方的数组中，每32字节空间相当于一个插槽，从0开始计数，每个插槽初始化为 0（最终存储只有不为0的插槽会存）
2. 每个变量根据类型具有不同的内存大小，根据定义顺序紧凑存储，直到占满32字节
3. 对于复杂数据类型，定义顺序的插槽可能只存储长度，或者对应的插槽号，值数据实际存储在经过运算的（例如keccack（插槽号））的插槽中，然后连续存储知道存储所有值

POC -- : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/





### 2024.09.08

学习內容:

做了A系列1题 - gatekeeperOne

今天主要是看了关于solidity类型转换的内容，具体内容，让我整理出一篇 blog吧

先大概梳理一下重点，

关于 gate2:

这个比较复杂，涉及到剩余的 gas 问题，必须是 8191的整数呗，所以整个 gas 应该是 8191 * n + x ，这个x是总共的消耗的 gas，这里关于他的解法有点疑惑

```solidity
      for (uint256 i = 0; i < 8191; i++) {
            (bool result, ) = address(gatekeeperOne).call{gas: i + 8191 * 3}(
                abi.encodeWithSignature("enter(bytes8)", _gateKey)
            );
            if (result) {
                break;
            }
        }
```

这个循环没有理清楚

关于gate3：

这里要做一个较为复杂的运算题，涉及到 显示转换以及隐式转换的位运算，截取哪里

**前提：**

byte8 = 8 字节，16字符，64 bit

地址类型 20字节，40字符，160 bit

假设 _gateKey = 0x0123456789abcdef

假设 tx.origin = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

- require1

  ```solidity
  (uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
  ```

  1. 条件1 ：uint32(uint64(_gateKey) = 0x89abcdef
  2. 条件2 ：uint16(uint64(_gateKey)) = 0x cdef = 0x0000cdef （隐式转换，两个数要比较，无符号整型可以转换成跟它大小相等或更大的字节类型） ****

  结论：_gateKey = 0x01234567**0000**cdef (5,6字节为0)

- require2

  ```solidity
  uint32(uint64(_gateKey)) != uint64(_gateKey)
  ```

  1. 条件1 ：uint32(uint64(_gateKey) = 0x0000cdef = 0x000000000000cdef
  2. 条件2 ：uint64(_gateKey) = 0x01234567**0000**cdef

  结论: 最后8位一定相等，则 _gateKey 前8位有一个不为0即可

- require3

  ```solidity
  (uint32(uint64(_gateKey)) == uint16(uint160(tx.origin))
  ```

  1. 条件1 ：uint32(uint64(_gateKey) = 0x0000cdef
  2. 条件2 ：uint16(uint160(tx.origin)) = 0xddC4 = 0x0000ddC4

  结论:  _gateKey 最后4位和 tx.origin 相等

总结论：_gateKey 8字节数， 前4字节至少有1位不为0，5,6字节为0，最后2字节和 tx.origin 相等，最后可以构造出这样的数字：**0x111111110000????**

(tx.origin 可以由攻击者获取，最后四位能拿到)



POC -- Gatekeeper One: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/GatekeeperOne.md





### 2024.09.09

学习內容:

做了A系列1题 - gatekeeperTwo

今天主要是看了 solidity 内联汇编，代码长度检查

思路：

### gateOne

很经典的 `msg.sender` 与 `tx.origin` 不相等，在 **Telephone** 和 **GatekeeperOne** 两关中都给出过解法，构建一个攻击合约调用即可

### gateTwo

caller()

- caller() ：当前函数的直接调用者
- extcodesize（a） ：地址 a 的代码大小 （eoa账户没有代码，大小为 0）

这里一开始不知道怎么限制 既是合约调用函数，又是Eoa账户，后面搜索知道了还有一种情况，extcodesize（a）为0：

合约在被创建的时候，runtime `bytecode` 还没有被存储到合约地址上， `bytecode` 长度为0。也就是说，将逻辑写在合约的构造函数 `constructor` 中，可以绕过 `extcodesize（a）` 检查。

### gateThree

这里要做一个运算题

**前提：**

type(uint64).max，8字节，16字符，64 bit，64位 1

^: 异或，相同为0，不同为1

keccak256(abi.encodePacked(msg.sender))：bytes32

```solidity
uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max
```

本来以为又涉及到类型转换时的截断算法，后面想起来，对于 异或 算法 ，a 异或 b = c， b = a 异或 c

结论：uint64(_gateKey) = type(uint64).max ^ uint64(bytes8(keccak256(abi.encodePacked(msg.sender))))

POC -- GatekeeperTwo: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/GatekeeperTwo.md



### 2024.09.10

学习內容:

今天仍然是在做题与写poc度过的，不过新学到了一些关于foundry的知识

做了A系列1题 - Naught Coin

思路：

这个合约限制了转账方法，时间锁了10年，但是对于继承 erc20 标准合约的token 来说，他还有transferfrom也能转账，不过需要结合 approve函数

foundry

今天主要是写了两个部署脚本，然后发现部署的时候这个 console.log还很有问题 ，值得研究，同时新发现了两个命令,查看账户余额，因为 call 去调的话必须是内置的函数，而向地址类型的全局变量就不在cast 命令里

```
cast balance 0x111111... --rpc-url
```

复现等明天补吧，每天都在赶之前的复现



### 2024.09.12

学习內容:

昨天清了一天假，今天仍然是在做题与写poc度过的，不过新学到了一些关于foundry的知识

今天主要是在复现 naughtcoin

学到了关于部署脚本里怎么切换用户

可以从环境变量中读取私钥

POC -- NaughtCoin: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/NaughtCoin.md



### 2024.09.14

学习內容:

昨天清了一天假，今天仍然是在做题与写poc度过的

做了A 系列一题 Preservation，加油杀出新手村

这道题结合了之前 delegatecall 的使用和插槽存储的特性

对于 delegate 来说，A合约它改变的都是某一插槽的变量，而B合约最好存储插槽的类型是一致的，否则无法修改，这里通过修改插槽 0 为指定地址的攻击合约地址，再在攻击合约中实现对应数据的修改，具体，等我整理 POC (POC已整理)

POC -- Preservation: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/Preservation.md



### 2024.09.15

学习內容:

今天仍然是在做题与写poc度过的

做了A 系列一题 Recovery，加油杀出新手村

这道题主要是对合约地址的计算，这里用的create

create 计算合约地址:

1. 使用 RLP 编码 msg.sender 与 创建者账户的 nonce
2. 对编码结果进行 keccake256 哈希
3. 将哈希结果转成地址类型

具体，等我整理 POC(已整理在下面)

POC -- Recovery: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/Recovery.md



### 2024.09.16

学习內容:

今天仍然是在做题与写poc度过的

整理之前的 poc 以及研究操作码



POC -- : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/



### 2024.09.17

学习內容:

中秋快乐，昨天晚上以及今天写了一个demo项目，花费了一点时间，ethernaut 跳过了3题（有点难度），做shop这道题

POC -- : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/

### 2024.09.18

学习內容:

工作又开始忙起来了，感觉这一期学不完ethernaut了

今天仍然是在做题与写poc度过的

今天做的 Daniel 这道题，这道题思路和之前的revert 很想，但是我按照类似的思路去做能成功组织owner调用，但是却没有成功解题，是 gas 的问题，对比两个调用的gas消耗，是差不多的，但是为什么直接revert 不成功呢？POC 待整理

POC -- : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/



### 2024.09.20

学习內容:

工作又开始忙起来了，感觉这一期学不完ethernaut了

今天仍然是在做题与写poc度过的

今天做的AlexCodex ，感觉在复杂数据里，动态数组还算简单的了，毕竟很好计算 数据值存储的位置。

这个合约中，提供了动态数组中指定下标元素的set方法，而我们知道 owner 变量和contact 变量一起存储 slot0 中。由于不能直接设置 slot 的值，所以，我们要想办法通过数组元素的 set 来更新 slot0 的值。

合约存储的数组是 2的256的长度，理论上是无限大的，但和 uint256 一样，如果出现了溢出，就会导致数组长度无限扩大，从而 codex 这个数组覆盖掉整个 状态变量存储的数组，这样，我们找到此时 slot0 存储的数组值，更新这个数组值就可以更新这个slot了

同样，POC待整理 

POC -- : https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/





### 2024.07.12

<!-- Content_END -->
