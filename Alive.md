---
timezone: Asia/Shanghai
---

# Alive

1. 自我介绍

   电子科技大学通信工程毕业，2020-2022深圳做过两年ios开发，2023开始接触链上撸毛，最近几个月想进一步学习区块链相关技能看能不能成为相关从业者。

2. 你认为你会完成本次残酷学习吗？

   应该会吧，每天挤出一两个小时应该没问题，只是不知道难度如何。

## Notes

<!-- Content_START -->

### 2024.08.29

解了下A系列习题的The Ethernaut的第0-8道题目。尽量都用foundry来解，时间有限，核心在快速把题目解出，代码的编排、规范可能差点。POC写在Writeup的foundry工程下。

这里讲讲各题的思路、感悟。

#### 第00题hello ethernaut

通过该例学习了下怎么用foundry与ethernaut互动

#### 第01题fallback

权限设置不当，通过适当的函数调用顺序即可获得合约所有权

#### 第02题fallout

调用fal1out即可

#### 第03题CoinFlip

链上数据都是透明，无法实现真正的随机，要随机数得通过chainlink

#### 第04题Telephone

主要是知道tx.orgin和msg.sender的区别

#### 第05题Token

solidity0.8.0之前是没有溢出检查的，需要用safemath来保证数据处理的安全。

#### 第06题Delegation

清楚call、delegatecall的用法即可解此题，想调函数时data可以abi.encodeWithSignature("functionName()")这种形式来传

#### 第07题Force

了解selfdestruct的用法即可解决。另外坎昆升级之后selfdestruct其实已被弃用，已经部署在链上的合约代码无法被真正删除。

#### 第08题Vault

同第03题，链上的所有东西都是透明的，千万不要把不想要别人知道的如钱包私钥的信息储存在链上。哪怕设置为private，也还是能通过slot读取到变量的值。

### 2024.08.30

#### 第09题King

通过在在receive中revert来实现合约拒绝接收value，从而使得King的转账逻辑失败，王位无法转移

#### 第10题ReEntrancy

经典重入问题，代码要养成遵循CEI模式的习惯。（Checks-Effects-Interactions pattern）

#### 第11题Elevator

把代码的部分逻辑外包给其他未经验证的合约是相当危险的，以这题为例，哪怕传入的参数都完全一样，但是返回的结果却不一样。

#### 第12题Privacy

和第08题Vault其实都是考察对slot的认识，只不过这题多考了个多变量公用一个slot的知识点。

#### 第13题GatekeeperOne

通过代码逻辑反推key就行，主要涉及到强制转换时位数截断的规则、位移运算、gasleft的使用、call带gas参数以及call中要调用具体函数时data要传abi.encodeCall(函数签名，参数)

#### 第14题GatekeeperTwo

类似第13题GatekeeperOne，通过代码逻辑反推key就行，主要涉及到extcodesize、^运算。通常用extcodesize是否为0来判断地址是合约地址还是eoa，但是合约在constructor阶段的extcodesize仍是0，因为还没正式上链，与evm机制有关。所以在涉及重要逻辑时，判断地址是合约地址还是eoa要综合判断，而不单单只靠extcodesize。

#### 第15题NaughtCoin

主要就是考察erc20的熟悉程度。erc20代币的转移有transfer和transferFrom两种方式。合约中只是重写了transfer加上了个时间锁，但是代币仍可通过transferFrom进行转移，转移之前不要忘了approve就行。

### 2024.08.31

#### 第16题Preservation

对delegatecall的更深入的考察。攻击合约调用了实例中的setFirstTime两次。第一次调用的时候实际上把实例中的timeZone1Library重置为攻击合约地址，第二次调用时实际delegatecall的对象已经变为了攻击合约，利用delegatecall的调用上下文保持不变特性，将攻击合约与状态变量与实例的状态变量对齐，从而实现在攻击合约中修改实例的owner的值。
由此例可看出，由于delegatecall操作的是调用合约的存储，如果处理不当，可能会导致严重的安全问题。例如，如果调用的目标合约地址可以由外部控制，攻击者可能会将调用者合约的存储更改为意料之外的状态。

#### 第17题Recovery

一种讨巧的方法是直接到区块浏览器上查交易记录找到部署的合约地址，还有一种就是poc中手动计算被部署的合约的地址。

#### 第18题MagicNumber

一些内联汇编的基本操作，比较偏evm底层。

### 2024.09.02

#### 第19题AlienCodex

利用老版本编译器没有做溢出检查的缺陷，不仅数值没做，数组也没做。

#### 第20题Denial

合约在call我们的攻击合约发送value时，将在recevie或fallback中将gas耗尽即可让owner withdraw失败。方法很多，写死循环、用assembly中的invalid()都可以将gas消耗完。但要注意如果只是revert是不行的。因为withdraw合约里并没有require call的结果要为true，所以给我们转账失败了也仍会给owner转账。

#### 第21题Shop

和第11题目elevator类似，把代码的部分逻辑外包给其他未经验证的合约是相当危险的，以这题为例，哪怕传入的参数都完全一样，但是返回的结果却不一样。和11题不同之处是外包的函数是view函数，无法在攻击合约中直接更改状态变量以针对调用返回不同结果。但我们可根据调用者自身状态变量（isSold）的变化来返回不同值。

#### 第22题Dex

getSwapPrice的计算是离散且有利于swap的人的，每次swap都会导致dex合约一些损失，多次来回倒后便可将其中一个池子掏空。不过要注意一下来回倒的过程中，合约剩余token、玩家手上token之间的数学关系。例如当玩家准备倒到另一种token时，合约剩余的那种token已经不足以支付结算出要支付的token数量时，就要调整swap的数量到刚好可以换完合约剩余token的数量即可。

### 2024.09.03

#### 第23题DexTwo

swap里并没有验证调用者要swap的代币是否是池子中的两个代币中的一个，而是只要满足ierc20即可。那么我们就可以通过构造虚假的erc20合约，用假的币换到池子里的真币。

#### 第22题PuzzleWallet

又是一次结合proxy对delegatecall的深入考察，这足以说delegatecall是安全漏洞的高发区。

<!-- Content_END -->
