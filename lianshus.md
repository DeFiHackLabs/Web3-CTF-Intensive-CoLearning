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

[POC]: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC/Fallback.md





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

[POC]: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus/POC

### 2024.09.01

学习內容:

这两天做了A系列1题

Token: 看到版本0.6就感觉是经典的uint256 整数溢出问题，但是记得以前做题是时间锁，哪个是上溢问题，这次也以为是这样，结果是下溢问题

总结了规律：

1. 加法上溢，超出最大范围变成最小值
2. 减法下溢，超出最小范围就变成最大值

[POC]: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus

### 2024.09.02

学习內容:

做了A系列1题

delegatecall : 进度非常慢，非常疑惑的一天

还是没怎么搞清楚，对于 delegation 来说，当调用不存在的函数时，会触发fallback，从而导致 使用 delegate 实例去 delegate call 函数，delegate call的原理，应该时使用 delegate 的代码修改 delegation 的状态，为什么没有更改回来呢？

以及，修复一个昨天的误区：用户转账超过余额给别人，但下溢后，导致自己的余额反而增加

[POC]: https://github.com/DeFiHackLabs/Web3-CTF-Intensive-CoLearning/tree/main/Writeup/lianshus

### 2024.07.12

<!-- Content_END -->
