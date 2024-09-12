## Usage

```shell
# on chain
forge script ./script/Level01.s.sol -vvvv --private-key $PRI_KEY --rpc-url https://rpc.ankr.com/eth_sepolia --broadcast
```

## Level 00 - Hello

### Target

1. 学习 Foundry 与链上合约的交互

### PoC

1. 请求 contract.password() 获取passkey
2. 请求 authenticate 解决solution

## Level 01 - Fallback

### Target

1. 学习合约如何接受/发送ETH
2. 理解修饰器的作用

### PoC

1. 发现receive函数修改了Owner，但是没有做权限控制
2. 为了满足receive函数中的修改Owner操作，因此请求 contribute 方法满足分支
3. 修改Owner后直接withdraw
4. 具体的PoC见 [Level 01-PoC](./script/Level01.s.sol)

## Level 02 - Fallout

### Target

1. 学习合约的构造函数

### Poc

1. 合约的构造函数必须为` constructor`，在solidity 0.4.22之前也使用类同名的构造函数

   ``` solidity
   contract TestConract {
   	constructor(address initialOwner) {
       	owner = initialOwner;
   	}
   	
   	// solidity 0.4.22之前的写法
       function TestConract(){
   		...
       }
   }
   ```

2. 所以那个constructor的注释主要是用于迷惑我们，直接调用Fal1out就可以完成了
3. 具体的PoC见 [Level 02-PoC](./script/Level02.s.sol)

## Level 03 - CoinFlip

### Target

1. 学习链上的随机数风险

### PoC

1. 采用了block.number和blockhash来进行伪随机数的生成，但是这些信息我们都可以直接获取
2. 部署对应的合约，进行相同的随机数生成算法计算，就能得到相同的结果
3. 为了保证block.number的不同，因此需要手动进行10次交易
4. 具体的PoC见 [Level 03-PoC](./script/Level03.s.sol)

## Level 04 - Telephone

### Target

1. 学习tx.origin和msg.sender的区别

### PoC

1. tx.origin是EOA账户的地址
2. msg.sender是调用合约的地址
3. 为了使tx.origin和msg.sender不一致，可以中间加入一个代理合约，利用代理合约去调用漏洞方法
4. 具体的PoC见 [Level 04-PoC](./script/Level04.s.sol)

## Level 05 - Token

### Target

1. 学习整数溢出漏洞

### PoC

1. 初始给予了20个token
2. 存在transfer交易，并且交易中直接扣除相应的数值，并没有使用safeMath或者其他校验
3. 对当前账户发起转账21token的交易，则直接发生整数溢出
4. 具体的PoC见 [Level 05-PoC](./script/Level05.s.sol)

## Level 06 - Delegation

### Target

1. 学习委托代理
2. fallback函数以及Call的用法

### PoC

1. 这里我们需要通过合约Delegation去调用Delegate的pwn方法
2. pwn方法中会修改Delegate合约的owner
3. 通过Delegatecall方法，并不会修改msg.sender，所以修改后的owner还是我们的玩家地址而不是Delegation的合约地址
4. 为了通过编译，我们在PoC要使用Call方法来调用Delegation中不存在的方法pwn
5. 具体的PoC见 [Level 06-PoC](./script/Level06.s.sol)

## Level 07 - Force

### Target

1. 学习selfdestruct

### PoC

1. Force合约中没有可以payable的函数
2. 查询Solidity官方文档发现存在selfdestruct，并且在selfdestruct的时候将合约剩余的eth转移到指定的账户中去
3. 构造一个新合约，存入1wei；在该合约上使用selfdestrcut，将challenge的地址作为转入地址实现转移eth
4. 具体的PoC见 [Level 07-PoC](./script/Level07.s.sol)

## Level 08 - Vault

### Target

1. 学习Solidity的内存模型

### PoC

1. 对于Private的数据，是无法直接通过合约进行访问。

   但是我们可以看到password存储在storage中，因此直接访问链上的Storage进行Leak

   参考[accessing-private-data-in-solidity](https://medium.com/@solidity101/100daysofsolidity-070-accessing-private-data-in-solidity-smart-contracts-unveiling-hacks-tests-7724485fe004)

   ```shell
   cast storage 0x72b3ea50eBACc33E49c079Be6559aF458cfc52e9 1 --rpc-url=https://rpc.ankr.com/eth_sepolia
   0x412076657279207374726f6e67207365637265742070617373776f7264203a29
   ```

2. 使用获取到的password进行解锁
3. 具体的PoC见 [Level 08-PoC](./script/Level08.s.sol)

## Level 09 - King

### Target

1. 学习Solidity Dos攻击原理

### PoC

1. 理解合约，合约实际完成的步骤如下
   1. 向合约转账，如果超过king的转价，则把转入的金额直接转给king。
   2. 转入者成为新的king。

2. 我们要实现保证不会再有新的king诞生，可以利用Solidity的Dos攻击，当有新的king产生时，在我们的`receive`函数中设置revert()操作，使得不会再有新的king产生。
3. 具体的PoC见 [Level 09-PoC](./script/Level09.s.sol)

## Level 10 - Reentrance

### Target

1. 学习Solidity的可重入攻击原理

### PoC

1. 这个是经典的可重入攻击模型，其实结合King来看，我们都可以发现主要在于调用call或者transfer时无法对接收方的receive操作做出过多限制。
2. 在receive函数中继续调用withdraw操作即可
3. 具体的PoC见[Level 10-PoC](./script/Level10.s.sol)

## Level 11 - Elevator

### Target

1. 学习基于接口实现合约

### PoC

1. 这道题实质就是希望我们实现一个Building接口的合约
2. 合约满足isLastFloor第一次调用返回False，第二次调用返回true
3. 我们只需要引入第三方变量，很轻易就能实现2的要求
4. 具体的PoC见[Level 11-PoC](./script/Level11.s.sol)

## Level 12 - Privacy

### Target

1. 学习[Solidity的内存模型](https://medium.com/@ozorawachie/solidity-storage-layout-and-slots-a-comprehensive-guide-2cee71817ed8)

### PoC

1. 参照Vault那题，使用cast工具查看合约的Storage空间获取私有变量的值

   ```shell
   cast storage 0xBa0A4a42D133c0Bb014C4900ED29D8EB7b47B3df 5 --rpc-url=https://rpc.ankr.com/eth_sepolia
   ```

2. 具体的PoC见[Level 12-PoC](./script/Level12.s.sol)

## Level 13 - GateKeeperOne

### Target

1. 学习Solidity的类型转换
2. 学习Solidity的gas

### PoC

1. 绕过tx.origin和msg.sender，设置中间代理合约即可
2. 绕过gasleft()，这个只能爆破，并且要使用call来调用合约方法，否则会因为revert而终止
3. 绕过最后的数字类型，三个条件可以得出
   1. 0x_ _ _ _ 00 00 _ _，第三位和第四位为0
   2. 第5位到第8位必定不为零
   3. 最低两位和tx.origin的最低两位相同
4. 具体的PoC见[Level 13-PoC](./script/Level13.s.sol)

## Level 14 - GateKeeperTwo

### Target

1. 学习solidity关于extcodesize的绕过

### PoC

1. tx.origin和msg.sender的绕过代理合约来实现
2. extcodesize是检查代码长度，对于合约地址这个函数的返回值大于0。但是在Solidity的合约创建时，extcodesize的值也为0，因此可以在构造函数中完成攻击。
3. 第三个绕过点就是异或的等价运算。
4. 具体的PoC见[Level 14-PoC](./script/Level14.s.sol)

## Level 15 - Naught Coin

### Target

1. 学习[ERC20代币协议](https://www.wtf.academy/docs/solidity-103/ERC20/)

### PoC

1. 时间锁只限制了player的直接转账操作
2. ERC20代币协议支持授权，因此我们将代币授权给其他合约
3. 其他合约将代币使用transferFrom方法转移即可
4. 具体的PoC见[Level 15-PoC](./script/Level15.s.sol)

## Level 16 - Preservation

### Target

1. 内存模型与DelegateCall

### PoC

1. 这题我们还是要理解DelegateCall的机制，DelegateCall的委托调用粗浅地理解就是只改变了code region，但是对于context仍然属于原有的合约。
2. 对于Storage，Delegate实际上是构建了对应的映射机制，类似指针。这里可以参照[这篇博客](https://medium.com/coinmonks/ethernaut-lvl-16-preservation-walkthrough-how-to-inject-malicious-contracts-with-delegatecall-81e071f98a12)
3. 通过1、2的分析，我们可以找到setTime的漏洞点，即修改的事实上是第0个slot的内容，而不是变量名误导我们认为的storedTime. 
4. 在3的基础上，我们就可以修改timeZone1Library的能力，将其修改为我们的恶意合约，在恶意合约中修改slot3的内容就成功修改了Owner。
5. 具体的PoC见[Level 16-PoC](./script/Level16.s.sol)

## Level 17 - Recovery

### Target

1. 掌握合约内创建合约的地址

### PoC

1. 题目的意思是SimpleToken的地址需要你找到
2. 因为没有存储在Storage，所以只能用其他方法获取
3. 合约的地址计算为 = keccak256(RLP(address, nonce))

   1. address就是当前Recovery的地址
   2. nonce表示创建的第几个合约，那么当前情况就1
   3. RLP是一种编码方式，具体可以参考Solidity相关文档，但是实际就是在address和nonce前添加bytes
4. 经过计算得到地址，通过selfdestruct就能够利用
5. 具体的PoC见[Level 17-PoC](./script/Level17.s.sol)

## Level 18 - Magic Number

### Targer

1. 学习EVM OPCODE
2. 学习EVM部署合约的过程

### PoC

1. 这道题其实要我们实现一个能够返回42这个数字的合约，但是要求这个合约地址的代码不超过10个字节

2. 为了实现这个需求，传统的构造函数是不足以满足的

3. 类似写Shellcode，我们需要利用EVM的OPCODE来实现我们的需求

   ```assembly
   PUSH1 0x2A
   PUSH1 0x80
   MSTORE		// 这一步就是实现将0x2a(42)写入内存中
   PUSH1 0x20
   PUSH1 0x80
   RETURN		// 这一步实现将32字节从0x80返回
   ```

4. 在构造合约的时候，我们实际就是向地址0x0存储数据，因此我们可以使用cast，也可以在合约中构造内联汇编来实现

   ```solidity
   contract SendTransaction {
       constructor () {
           assembly {
               mstore(0, 0x602A60805260206080F3)
               return(0x16,0x0a)
           }
       }
   }
   ```

5. 具体的PoC见[Level 18-PoC](./script/Level18.s.sol)

## Level 20 - Denial

### Target 

1. 学习Gas限制的DoS攻击方式

### PoC

1. 这题不能使用revert来限制对于owner的转账，因为使用的底层的call方法来进行转账
2. 除了使用revert/不写接受eth的方法来进行DoS之外，还可以使用gas限制来进行DoS攻击
3. 在我们的fallback函数中增加死循环从而增加gas的消耗，最后使得交易失败
4. 具体的PoC见[Level 20-PoC](./script/Level20.s.sol)

## Level 21 - Shop

### Target 

1. 学习利用额外变量构造逻辑分支

### PoC

1. 这题类似我们之前Elevator那题，需要在一个函数中根据不同的调用时机返回不同的值
2. Elevator我们可以使用Storage的变量来作为标志变量，但是这题用的view修饰符，在view函数中我们只能访问Storage的变量，不能进行修改，因此我们在Elevator的方法失效了
3. 一个思路，就是用block相关的变量，在web2中，类似timestamp的方式来做，但是在Web3就不太合理了
4. 实现的思路是查看两次调用之间发生了什么，发现在isSold变量的值上存在差异，因此可以构造差异性形成逻辑分支。
5. 具体的PoC见[Level 21-PoC](./script/Level21.s.sol)

## Level 22 - DEX

### Target

1. 学习DEX以及token兑换
2. 学习基于整数的价格操纵漏洞

### PoC

1. 这题的关键在于针对汇率的计算，对于漏洞的理解可以基于下列的手动推算过程。

   ```
   // 10 token1 换成 10 token2
   token1			token2			token1(DEX)		token2(DEX)
   0				20				110				90
   // 20 token2 全部换成token1
   24				0				86				110
   ```

2. 经过简单的推算，我们可以只是简单的汇率兑换，我们的token就增多了。这实际上是因为汇率计算时采用的是整数除法，这中间产生了误差。
3. 我们的策略就是将手上的tokenA全部转换为tokenB，同时因为减少了池子中的tokenB，拉高了tokenB的汇率，tokenB能够换回更多的tokenA。
4. 以此类推，我们可以在DEX无法一次性吃下我们手上的全部token时，将另一种token全部收入囊中。
5. 具体的PoC见[Level 22-PoC](./script/Level22.s.sol)

## Level 23 - DexTWO

### Target

1. 学习DEX
2. 学习并部署ERC20代币

### PoC

1. 在一题的基础上，我们要实现对于token1和token2的一网打尽
2. 经过分析，我们可以看到，单纯在token1和token2之间进行交换是没办法完成一网打尽的
3. 在DexTWO的swap函数中不再要求只进行token1和token2之间的交换
4. 因此，我们只需要部署一个token3，让token3参与交换，就可以将token1和token2中剩余的那个一网打尽
5. 具体的PoC见[Level 23-PoC](./script/Level23.s.sol)

## Level 24 - PuzzleWallet

### Target

1. storage与delegateCall的关系
2. 逻辑漏洞

### PoC

1. 在之前的题目已经做过，delegateCall需要我们去注意Storage实际是构建了映射关系，真正的上下文是保留在委托发起的合约，因此我们可以通过proposeNewAdmin方法来修改owner
2. 成为owner之后，我们可以将自己加为白名单
3. 根据1，同理我们可以通过setMaxBalance来使得自己成为admin，但是这需要我们crack账户的balance
4. 回头来看multicall，这里的风险在于我们可以通过重复调用multicall从而绕过了depositCalled这个限制
5. 具体的PoC见[Level 24-PoC](./script/Level24.s.sol)

