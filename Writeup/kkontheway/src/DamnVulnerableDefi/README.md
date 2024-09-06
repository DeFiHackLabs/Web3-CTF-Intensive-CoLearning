- [Shards](#shards)
- [Abi-smuggling](#abi-smuggling)
- [Withdrawal](#withdrawal)
- [Wallet Mining](#wallet-mining)
  - [Desc](#desc)
  - [Code](#code)
  - [Solution](#solution)

## Shards

**Goal**

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

**Soultion**

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


## Abi-smuggling
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
    - 初始化合约，通过赋予`player` `withdraw()`的权限，赋予`deployer` `sweepfund()`的权限

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

代码验证的流程是先从`actionData`中取出要调用的函数的`selector`，然后将`selector`和我们的地址还有`target`进行`keccak256`，最后检查`permissions`，所以我们的目的就是欺骗他我们调用的是`withdraw` ，其实我们调用的是`sweepfunds`函数。

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
**EXP**

##  Withdrawal

**Goal**

```solidity
1_000_000e18 * 99% <token.balanceOf(address(l1TokenBridge)) < 1_000_000e18
token.balanceOf(player) == 0
l1Gateway.counter() >= 4

```

**Code**

- TokenBridge
    - executeTokenWithdrawal
        - 用于代币提取
        - 有权限校验
- L2MessageStore
- L2Handler
- L1GateWay
- L1Forwarder

**Solutions**

因为这道题目补习了一下关于`Event`中的内容,具体就不多展开，大家可以查看`WTF`的[Event](https://www.wtf.academy/docs/solidity-101/Event/#evm%E6%97%A5%E5%BF%97-log)一章节

总结就是日志的第一部分是`Topics`的数组，数组的第一个元素是事件的`hash`值，之外主题还可以包含至多`3`个`indexed`参数。而事件中不带`indexed`的元素会被放在`data`中，可以理解为事件的“值”。**`data`** 部分的变量不能被直接检索，但可以存储任意大小的数据。因此一般 **`data`** 部分可以用来存储复杂的数据结构，例如数组和字符串等等，因为这些数据超过了256比特，即使存储在事件的 **`topics`** 部分中，也是以哈希的方式存储。另外，**`data`** 部分的变量在存储上消耗的`gas`相比于 **`topics`** 更少。

所以题目给出的`json`就可以理解如下:

```solidity
{
        "topics": [
            "0x43738d035e226f1ab25d294703b51025bde812317da73f87d849abbdbb6526f5", // 事件的hash
            "0x0000000000000000000000000000000000000000000000000000000000000000", // uint256 indexed nonce
            "0x00000000000000000000000087EAD3e78Ef9E26de92083b75a3b037aC2883E16", // address indexed caller
            "0x000000000000000000000000fF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5"  // address indexed target = l1Forwarder
        ],
        "data": "0xeaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba0000000000000000000000000000000000000000000000000000000066729b630000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010401210a380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004481191e51000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac60000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
		    // data中是不带indexed的参数 “id,timestamp,data”
    },
```

我们再来解析一下`data`, `data`中应该包含三个参数`bytes32 id`, `uint256 timestamp`, `bytes data`

```solidity
event MessageStored(
        bytes32 id, uint256 indexed nonce, address indexed caller, address indexed target, uint256 timestamp, bytes data
    );
```

```solidity
0x
eaebef7f15fdaa66ecd4533eefea23a183ced29967ea67bc4219b0f1f8b0d3ba // bytes32 id
0000000000000000000000000000000000000000000000000000000066729b63 // uint256 timestamp
0000000000000000000000000000000000000000000000000000000000000060 // bytes data offset
0000000000000000000000000000000000000000000000000000000000000104 // length
01210a38                                                         // forwarder.sig
0000000000000000000000000000000000000000000000000000000000000000 // nonce
000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6 // address l2sender
0000000000000000000000009c52b2c4a89e2be37972d18da937cbad8aa8bd50 // address target
0000000000000000000000000000000000000000000000000000000000000080 // bytes message offset
0000000000000000000000000000000000000000000000000000000000000044 // length
81191e51                                                         // executeTokenWithdrawal.sig
000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac6 // address receiver
0000000000000000000000000000000000000000000000008ac7230489e80000 // amount 10e18
0000000000000000000000000000000000000000000000000000000000000000
```

总共有四个log，他们依次的提款amount是:

- 10e18
- 10e18
- 999,000e18
- 10e18

所以很明显第三个是我们的恶意的提款请求，好在我们有7天的delay，钱还在。

根据我们上面的解析结果，我们应该可以理解整个系统运作的逻辑，首先L2 System会调用L2MessageStore来发送一个L2sender的消息，然后L1在捕获到这个消息后会处理，然后解析该消息，就会调用L1forwarder，接下来L1forwarder就会解析详细，然后将调用流程装给TokenBridge。

所以调用流程和Message的解析，我们的调用顺序应该是:

- L1Gateway.finalizedWithdrawal
- L1Forwarder.forwardMessage
- TokenBridge.executeTokenWithdrawal

解题条件中有一个是要完成四次提款，三次正常的我们可以直接通过他们json文件中的内容来进行，那还有一次呢，我们肯定不可以执行第三个会提取99%资产的那个，那我们肯定不能执行，所以我们要伪造一次，该怎么伪造呢，他是有Merkle验证的呀,该怎么绕过呢:

在Setup中，我们player被赋予了operator的角色，有了这个角色我们就不需要进行merkle的验证了

```solidity
// withdrawal.t.sol
l1Gateway.grantRoles(player, l1Gateway.OPERATOR_ROLE());

// L1Gateway.sol
// Only allow trusted operators to finalize without proof
        bool isOperator = hasAnyRole(msg.sender, OPERATOR_ROLE);
        if (!isOperator) {
            if (MerkleProof.verify(proof, root, leaf)) {
                emit ValidProof(proof, root, leaf);
            } else {
                revert InvalidProof();
            }
        }

```

所以我们可以直接伪造。


## Wallet Mining


### Desc

```jsx
There’s a contract that incentivizes users to deploy Safe wallets, rewarding them with 1 DVT. It integrates with an upgradeable authorization mechanism, only allowing certain deployers (a.k.a. wards) to be paid for specific deployments.

The deployer contract only works with a Safe factory and copy set during deployment. It looks like the [Safe singleton factory](https://github.com/safe-global/safe-singleton-factory) is already deployed.

The team transferred 20 million DVT tokens to a user at `0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b`, where her plain 1-of-1 Safe was supposed to land. But they lost the nonce they should use for deployment.

To make matters worse, there's been rumours of a vulnerability in the system. The team's freaked out. Nobody knows what to do, let alone the user. She granted you access to her private key.

You must save all funds before it's too late!

Recover all tokens from the wallet deployer contract and send them to the corresponding ward. Also save and return all user's funds.

In a single transaction.
```

### Code

- AuthorizerFactory.sol
    - cook
        - 用于创建Safe钱包的代理工厂合约地址
- AuthorizerUpgradeable.sol
    - 实现合约
- TransparentProxy.sol
    - 代理合约
- WalletDeployer.sol
    - cpy safe钱包的实现合约地址
    - 用来给Gnosis的部署者分发奖励
    - can
    - rule
    - drop

### Solution

正如描述所说，当团队试图将 `2000` 万个代币转移给 '`0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b` 的用户但丢失了 `nonce`.这意味着此地址没有合约。我们可以使用 `CREATE2` 创建一个具有相同地址的帐户。  我们可以使用`SafeProxyFactory::createProxyWithNonce` 来暴力破解地址。

```solidity
  function createProxyWithNonce(address _singleton, bytes memory initializer, uint256 saltNonce) public returns (SafeProxy proxy) {
      // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
      bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
      proxy = deployProxy(_singleton, initializer, salt);
      emit ProxyCreation(proxy, _singleton);
  }
```

我们可以编写一个循环来进行爆破

```solidity
for (uint256 i = 0; i < 10000; i++) {
    SafeProxy proxy = proxyFactory.createProxyWithNonce(
        address(singletonCopy),
        initializer,
        i
    );
    if (address(proxy) == USER_DEPOSIT_ADDRESS) {
        console.log("Wallet deployed at address: ", address(proxy));
        console.log("with Nonce: ", i);
        break;
    }
}
```

接下来要考虑的问题是，已经在WalletDeployer中的1e18的token怎么取走，`WalletDeployer::drop`函数依赖于授权者合约来检查允许哪个用户创建钱包并获得奖励，`AuthorizerUpgradeable`是一个可升级的合约，可以通过透明代理模式进行升级我发现他的初始化是错误的，因为代理合约和实现合约之间的存储布局不同，因此会导致冲突。

```solidity
contract TransparentProxy is ERC1967Proxy {
    address public upgrader = msg.sender;  // slot 0
}
---

contract AuthorizerUpgradeable {
    uint256 public needsInit = 1;  // slot 0
    mapping(address => mapping(address => uint256)) private wards; // slot 1
}
```

`needsInit`变量与代理的`upgrader`变量存储在同一存储槽中。这意味着，当`AuthorizerUpgradeable::init`函数时， `needsInit`变量将设置为`0` ，但之后调用`TransparentProxy::setUpgrader`时，代理的`upgrader`变量将设置为`needsInit`者的地址，从而有效地用非零值，从而允许重新初始化

这样我们就可以重新初始化AuthorizerUpgradeable合约，并且将wards设置为users地址，因为用户向我们提供了他们的私钥来保存他们的资金，所以我现在可以将 2000 万个 DVT 代币从安全钱包转回给用户，并从钱包中转回 1 个 DVT 代币到原来的ward中。