---
timezone: Asia/Shanghai 
---

# xiaopai

1. 自我介绍
互联网公司码农，想学习下web3相关技术

2. 你认为你会完成本次残酷学习吗？
应该能够每天能抽出1h学习，可以完成本次学习

## Notes

<!-- Content_START -->

### 2024.08.29

#### Ethernaut
##### 第一题
按照提示完成

##### 第二题
1. 利用 receive 函数的漏洞，直接 sendTransaction 就可以成为owner。
2. gas费有点贵，各种找水龙头花了点时间
3. 直接在浏览器的 console 交易 gas 费很贵，自己直接用 ethers.js 指定 gasPrice 可以少很多gas费

##### 第三题
构造方法拼写错误导致的漏洞，可以直接调用即可。

#### 其他
1. sepolia 水龙头
```
https://access.rockx.com/faucet-sepolia
https://www.alchemy.com/faucets/ethereum-sepolia
```
2. 今天进展不多，了解了Web3-CTF的玩法

### 2024.08.30
请假

### 2024.08.31
#### Foundry学习
1. 看很多同学都使用Foundry来做题，了解了下。安装好了环境，发现使用cast命令调用合约确实很方便
2. 但是涉及到签名的命令就报错，暂时没解决，很奇怪，只能先继续使用ethers.js做题


### 2024.09.02
#### Ethernaut
Ethernaut 进展快起来了，熟悉了 Foundry 的常用命令，效率确实快很多。
##### 第5题 Telephone
1. 了解了tx.origin 跟 msg.sender 的区别

##### 第6题 Token
1. 利用 0.6.0 版本的uint计算时的溢出漏洞

##### 第7题 Delegation
1. delegatecall的用法及风险点，一般用户存储跟计算逻辑拆分，这样可以解耦跟复用。

##### 第8题 Force
1. 自杀式攻击，这个感觉用户不大，了解合约销毁的方式

##### 第9题 Vault
1. 合约上private的变量不是真的隐私不可见
2. 攻击方式也很有意思，Foundry提供的测试相关的工具类很强大，示例代码如下
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

contract VaultSolution is Script {
    using stdStorage for StdStorage;

    address constant LEVEL_INSTANCE = 0x0D...4E;

    function run() public {
        bytes32 password = vm.load(LEVEL_INSTANCE, bytes32(uint256(1)));
        console2.logBytes32(password);
    }
}
```

### 2024.09.03
#### Ethernaut
##### 第9题 King
1. 逻辑比较简单
2. 遇到一个报错卡主， 原因是transfer send 发送eth的时候，对方的receive fallback不能太复杂，因为有gas上限是2300，如果发生失败可以使用call 可参考https://www.wtf.academy/docs/solidity-102/SendETH/
```
      transfer  _to.transfer(amount);
      send   _to.send(amount);
      call _to.call{value: amount}("");
```

##### 第10题 ReEntrancy
1. 没想到思路，找到了相关可重入攻击资料，但是poc没跑通，还在找原因。
```
直接报 server returned an error response: error code -32000: execution reverted 很奇怪
```
### 2024.09.04
#### Ethernaut
##### 第10题 ReEntrancy
1. 终于找到了昨天报错的原因，cast send 时候传入的函数签名不对，本来应该是 uint256 但是传了 address。 居然不报函数找不到异常...太难排错了，在remix调试都没看出来

##### 第11题 Elevator
1. 很简单，记录当前是第几次调用，第一次返回false， 第二次返回true即可。

##### 第12题 Privacy
1. 了解变量的存储结构 + vm.load 即可解决。

### 2024.09.05
请假

<!-- Content_END -->
