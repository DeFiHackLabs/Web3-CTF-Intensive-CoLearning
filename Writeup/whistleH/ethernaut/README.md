## Usage

```shell
# on chain
forge script ./script/Level01.s.sol -vvvv --private-key $PRI_KEY --rpc-url https://rpc.ankr.com/eth_sepolia --broadcast
````

## Level 00-Hello

### Target

1. 学习 Foundry 与链上合约的交互

### PoC

1. 请求 contract.password() 获取passkey
2. 请求 authenticate 解决solution

## Level 01-Fallback

### Target

1. 学习合约如何接受/发送ETH
2. 理解修饰器的作用

### PoC

1. 发现receive函数修改了Owner，但是没有做权限控制
2. 为了满足receive函数中的修改Owner操作，因此请求 contribute 方法满足分支
3. 修改Owner后直接withdraw
4. 具体的PoC见 [Level 01-PoC](./script/Level01.s.sol)

## Level 02-Fallout

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

## Level 03-CoinFlip

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



