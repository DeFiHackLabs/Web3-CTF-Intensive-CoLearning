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

