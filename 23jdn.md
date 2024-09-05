---
timezone: Asia/Shanghai
---
---

# 23jdn

1. 自我介绍: 传统安全人员，为踏入web3安全做准备
2. 你认为你会完成本次残酷学习吗？：尽量完成

## Notes

<!-- Content_START -->

### 2024.08.29

今日概况:
之前实操时一般习惯在remix VM或Truffle上进行题目合约代码的部署以及后续的交互，与Foundry的交互比较少，今天大部分时间了解环境的部署与后续的题目选择。

#### Foundry curl(7)错误

Foundry安装方法比较简单，但由于其他因素可能会导致一些问题，目前遇到的问题为网络环境问题被墙导致执行curl -L https://foundry.paradigm.xyz | bash 出现curl(7)的错误，本想着通过docker pull部署，但由于网络被墙的问题以及ubuntu下无法配置全局网络代理导致docker pull失败，后面了解到curl(7)该错误由于使用的节点与“raw.githubusercontent.com”网站出现dns解析异常而导致失败，通过https://www.ipaddress.com 查询对应域名dns解析Ip 添加对应ip到系统文件hosts处实现强制指向从而解决curl(7)错误

### 2024.08.30

#### ethernaut系列-Fallback:

题目要求完成以下条件

- 获得这个合约的所有权
- 把合约内的余额减到0

关卡代码如下:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {
    mapping(address => uint256) public contributions;
    address public owner;

    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
```
分析:通过阅读sol代码可知，合约初次部署时将msg.sender发送者作为了owner，修改owner权限的地方只有在receive方法中存在，receive作为一个合约接受到eth转账时自动触发的函数。代码内判定发送eth的value>0 wei (默认eth单位为wei)以及contributions内的余额>0，即可将owner发送给消息发送者。contribute函数在接受贡献时做了判定，接受eth要小于0.0001个eth，通过符合条件的要求即可获取合约owner权限。拥有owner权限后再调用withdraw方法提取合约内的eth余额即可满足所有要求。

**附:由于foundry还在熟悉中，以上操作均在remix上进行部署调用，后续了解foundry后补上对应poc**


#### ethernaut系列-Fallout

题目要求获得合约所有权

关卡代码如下:

**附:safemath的库导入import "openzeppelin-contracts-06/math/SafeMath.sol";在remix中需要改为import "@openzeppelin/contracts/math/SafeMath.sol";**
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Fallout {
    using SafeMath for uint256;

    mapping(address => uint256) allocations;
    address payable public owner;

    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }

    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }

    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function allocatorBalance(address allocator) public view returns (uint256) {
        return allocations[allocator];
    }
}
```

分析:合约代码非常简单这里不做太多描述，直接调用Fallout方法即可，owner在最开始定义的时候并没有赋值，所以最初owner对应地址为0x00000


#### ethernaut系列-CoinFlip
题目要求连续猜对10次硬币

CoinFlip代码如下:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {
    uint256 public consecutiveWins;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() {
        consecutiveWins = 0;
    }

    function flip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
}
```


分析:该合约通过获取当前区块高度-1(由于当前交易所在区块打包上链进行广播此时是获取不到当前区块的hash的，随意采用获取上一个区块)的区块哈希值与预定义好的FACTOR进行相除来模拟一个硬币的正反面，由于FACTOR是一个很大的值相除只会得到1 or 0的结果(blockvalue是一个uint256的变量),并通过连续猜对次数的记录作为猜对次数判定。由于区块hash算一个伪随机数，所以在同样的环境下运行同样的算法即可得到一样的结果，其关键在于本地运算与目标合约的flip的调用在同一笔交易(也就是同一区块)中实现即可得到同样的hash，在计算好结果后在调用CoinFilp的flip函数代入即可猜对对应结果。

[CoinFlip-poc](./Writeup/23jdn/test/ethernaut/CoinFlip.t.sol)

### 20240902

#### ethernaut系列-Telephone

题目要求修改owner地址

Telephone:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
```

分析:gas费用始终为tx.origin支付，msg.sender为合约当前调用者，通过一笔交易中采用中间人调用合约即可完成tx.origin!=msg.sender的判定

[Telephone-poc](./Writeup/23jdn/test/ethernaut/Telephone.t.sol)


#### ethernaut系列-Token

题目要求增加代币

Token Code:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {
    mapping(address => uint256) balances;
    uint256 public totalSupply;

    constructor(uint256 _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
```
0.6.0版本存在溢出，直接进行转账即可

[Token-poc](./Writeup/23jdn/test/ethernaut/Token.t.sol)

### 20240903

#### ethernaut系列-Delegation

题目要求修改owner

Delegation code:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
```

分析:delegatecall调用与传统的call调用的区别在于调用的语境不同，delegatecall允许一个合约在调用另一个合约时，将调用者的上下文（包括存储和 msg.sender）传递给被调用的合约，这样会导致存储变量的覆盖从而导致调用pwn()产生owner的更改。

[Delegation-poc](./Writeup/23jdn/test/ethernaut/Delegation.t.sol)

#### ethernaut系列-Force

题目要求合约的余额大于0

Force code:
```// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }

```

分析:合约虽然没有fallback、revice方法处理接受eth的功能，但是如果一个合约销毁时发送的eth无条件接受。

[Force-poc](./Writeup/23jdn/test/ethernaut/Force.t.sol)

#### ehternaut系列-Vault

题目要求打开 vault

Vault code:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
    bool public locked;
    bytes32 private password;

    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }

    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}
```
分析:private变量可以通过直接访问存储槽来实现，在 Solidity 中，私有状态变量只是对合约外部的不可见性，但依然存储在区块链上.

参考链接:
[https://learnblockchain.cn/article/3398](!https://learnblockchain.cn/article/3398)

[Vault-poc](./Writeup/23jdn/test/ethernaut/Vault.t.sol)

### 20240904

#### ethernaut系列-King

题目要求阻止他人获得king

King code:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
```

分析:创建一个不可接受eth转账的合约即可更改对应逻辑

[King-poc](./Writeup/23jdn/test/ethernaut/King.t.sol)

#### ethernaut系列-Reentrance

题目要求清空合约资产

Reentrance Code:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts/math/SafeMath.sol";

contract Reentrance {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
```

分析:重入攻击

[Reentrance-poc](./Writeup/23jdn/test/ethernaut/Reentrance.t.sol)


### 20240905 

#### ethernaut系列-Elevator

题目要求电梯达到顶层

Elevator code:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}
```

1


<!-- Content_END -->
