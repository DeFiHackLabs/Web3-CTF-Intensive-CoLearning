---
timezone: Asia/Shanghai
---

---

# awmpy

1. 自我介绍
我是一名后端开发工程师，负责公司云靶场的开发工作，熟悉OpenStack与Kubernetes等云计算技术


2. 你认为你会完成本次残酷学习吗？
一定可以

## Notes

<!-- Content_START -->

### 2024.08.29

- Ethernaut

#### 0. Hello Ethernaut

根据提示在浏览器控制台中输入相应的命令即可
需要注意的是：

通过`contract.abi`查看所有可用的方法，再通过`contract.password()`方法获取密码

#### 1. Fallback

查看合约代码后发现receive方法中满足贡献值>0与发送交易的value>0时会将owner设置为sender

首先用小于0.001eth向合约捐献，调用contribute()函数，使我们拥有贡献值

``` bash
await contract.contribute.sendTransaction({ from: player, value: toWei('0.0009')})
```

向合约发送一些eth，触发receive，获取owner

``` bash
await sendTransaction({from: player, to: contract.address, value: toWei('0.000001')})
```

调用withdraw提取余额

``` bash
await contract.owner()
```

#### 2. Fallout

这个合约中构造函数拼写错误导致任何人都可以调用Fal1out函数来获取owner权限

``` bash
await contract.Fal1out()
```

### 2024.08.30

#### 3. Coin Flip

这个挑战的核心点在于eth上的随机数是伪随机数，可直接按照合约中的算法写一遍来获取猜硬币结果

为了保证计算合约和题目的合约是在同一个区块中，因此需要写一个攻击合约来完成此次攻击

被攻击的合约地址需要写成ethernaut生成的合约地址

##### remix

使用remix部署[合约](Writeup/awmpy/remix/ethernaut_coin_flip_hack.sol)，写入ethernaut合约地址作为target

调用10次flip函数，即可过关

##### foundry

在`Writeup/awmpy`目录下执行`forge init`初始化forge项目

将CoinFlip的代码复制到[coin_flip.sol](Writeup/awmpy/src/ethernaut/coin_flip.sol)

在`Writeup/awmpy`目录下新建`.env`文件，在文件中写入`PRIVATE_KEY`环境变量，此变量会在脚本文件中被调用

编写脚本[coin_flip_hack.s.sol](Writeup/awmpy/script/ethernaut/coin_flip_hack.s.sol)，计算guess并调用ethernaut生成的合约，脚本中直接写死合约地址

执行命令进行调用10次后，即可过关

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/coin_flip_hack.s.sol:CoinFlipHackScript -vvvv --broadcast
```

### 2024.08.31

#### 4. Telephone

这个挑战的核心点在于考察`msg.sender`和`tx.origin`的知识，`msg.sender`可能是EOA或合约，`tx.origin`只能是EOA

因此只需要实现以下调用链即可：

``` bash
EOA ==> AttackContract ==> TelephoneContract
```

编写攻击合约[telephone_hack.sol](Writeup/awmpy/src/ethernaut/telephone_hack.sol)
部署攻击合约，部署时指定合约地址为ethernaut生成的合约地址

``` bash
forge create --constructor-args "0xFce4169EcEa2f8FA0A12B0312C96Beb8d8734E76" --rpc-url https://1rpc.io/holesky --private-key $PRIVATE_KEY src/ethernaut/telephone_hack.sol:TelephoneHack
```

编写执行脚本[telephone_hack.s.sol](Writeup/awmpy/script/ethernaut/telephone_hack.s.sol)，其中攻击合约地址为刚部署的攻击合约地址
执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/telephone_hack.s.sol:TelephoneHackScript -vvvv --broadcast
```

#### 5. Token

这个挑战是考察溢出漏洞，Token合约使用的版本是0.6.0，且没有使用SafeMath

此题目给玩家预分配了20枚代币，因此只需要调用合约的`transfer`方法向任意地址转移`21`枚代币就可以触发漏洞

编写攻击脚本[token_hack.s.sol](Writeup/awmpy/script/ethernaut/token_hack.s.sol)，其中实例化Token合约使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/token_hack.s.sol:TokenHackScript -vvvv --broadcast
```

### 2024.09.01

#### 6. Delegation

这个挑战是考察Delegatecall相关知识

`Delegation`合约中实现了一个`fallback`函数，在调用此合约中不存在的函数时，`fallback`函数就会被调用，将原来的calldata传递给它

`Delegate`合约中实现了一个`pwn`方法，将`owner`改为`msg.sender`

而在`Delegatecall`时，`msg.sender`和`msg.value`都不会改变，只需要写脚本调用`Delegation`合约的`pwn`方法即可获得`Delegate`合约的`owner`权限

调用`pwn`方法时需要使用`abi.encodeWithSignature`将函数名转为`function signature`进行调用

编写攻击脚本[delegation_hack.s.sol](Writeup/awmpy/script/ethernaut/delegation_hack.s.sol)，其中实例化Token合约使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/delegation_hack.s.sol:DelegationHackScript -vvvv --broadcast
```

### 2024.09.02

#### 7. Force

考察selfdestruct知识，编写一个合约，自毁时强制把一些eth转给目标合约地址即可

编写攻击脚本[force_hack.s.sol](Writeup/awmpy/script/ethernaut/force_hack.s.sol)，其中转账地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/force_hack.s.sol:ForceHackScript -vvvv --broadcast
```

### 2024.09.03

#### 8. Valut

这是一个猜密码的游戏，需要用到数据存储相关的知识

每个存储槽将使用32个字节（一个字大小）
对于每个变量来说，会根据其类型确定以字节为单位的大小
如果可能的话，少于32字节的多个连续字段将根据以下规则被装入一个存储槽
一个存储槽中的第一个项目以低位对齐的方式存储
值类型只使用存储它们所需的字节数
如果一个值类型在一个存储槽的剩余部分放不下，它将被存储在下一个存储槽
结构和数组数据总是从一个新的存储槽开始，它们的项目根据这些规则被紧密地打包
结构或数组数据后面的项目总是开始一个新的存储槽

`locked`变量存储在slot0，`password`变量因为是32字节类型，无法存放到slot0，只能是在slot1中

在foundry中使用`vm.load`来获取`password`变量内容

编写攻击脚本[vault_hack.s.sol](Writeup/awmpy/script/ethernaut/vault_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/vault_hack.s.sol:VaultHackScript -vvvv --broadcast
```

### 2024.09.04

#### 9. King

这是一个关于DOS攻击的游戏
区块链上较为常见的攻击方式有`消耗过高的GAS`、`External call导致合约不受控`

[WTF-Solidity案例](https://github.com/AmazingAng/WTF-Solidity/blob/main/S09_DoS/readme.md)

[消耗GAS过高的案例](https://solidity-by-example.org/hacks/denial-of-service/)

这个挑战就是要通过`External call`的方式，让其他人无法获得王位

`King`合约中实现了一个`receive`函数，会在转账给这个合约时触发，但转账金额要大于当前King的prize，通过校验后就会将Ether转给当前King，再把`msg.sender`设置为新的king

而这里又没有规定King是EOA还是合约

因此有了以下攻击思路:

1. 编写一个合约，给`King`合约转账触发`King`合约的`receive`函数来使攻击合约成为King
2. 攻击合约中实现一个估计将交易revert掉的`receive`方法让其他人无法再向King转账，以次实现DOS的目的

编写攻击合约[king_hack.sol](Writeup/awmpy/src/ethernaut/king_hack.sol)
编写攻击脚本[king_hack.s.sol](Writeup/awmpy/script/ethernaut/king_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/king_hack.s.sol:KingHackScript -vvvv --broadcast
```

### 2024.09.05

#### 10. Re-entrancy

`Re-entrancy`是一种常见的攻击手法，利用合约external call外部合约时，外部合约故意回call原始合约，让原始合约再次执行external call，直到达成攻击者目的或GAS耗尽，由于攻击者会二次或多次进入目标合约，故被称为重入攻击

在`Re-entrancy`合约的`withdraw`函数中:

1. 先检查提款者的余额是否足够
2. 将`_amount`转入提款者账户
3. 最后修改提款者的余额

攻击手法:

1. 攻击合约调用`donate`函数，存入一些Ether
2. 攻击合约调用`withdraw`函数，提取存入的Ether，让external call触发攻击合约的`receive`函数
3. 攻击合约的`receive`函数再次调用目标合约的`withdraw`函数
4. 重复2-3直到目标合约中所有的Ether都被转走，而修改提款者余额这一步永远不会执行

编写攻击合约[reentrance_hack.sol](Writeup/awmpy/src/ethernaut/reentrance_hack.sol)
编写攻击脚本[reentrance_hack.s.sol](Writeup/awmpy/script/ethernaut/reentrance_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/reentrance_hack.s.sol:ReentranceHackScript -vvvv --broadcast
```

#### 11. Elevator

这一题比较简单，攻击合约中实现一个`isLastFloor`方法，并且第一次被调用时return false，第二次被调用时return true就能将top设置为true

编写攻击合约[elevator_hack.sol](Writeup/awmpy/src/ethernaut/elevator_hack.sol)
编写攻击脚本[elevator_hack.s.sol](Writeup/awmpy/script/ethernaut/elevator_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/elevator_hack.s.sol:ElevatorHackScript -vvvv --broadcast
```

### 2024.09.06

#### 12. Privacy

这一提与Valut十分相似，都是需要通过获取变量的值来通关，核心点还是变量存储的问题，找到密码所在的slot

经过以下推算可以得知`data[2]`存储在`slot5`中
|var                                 |bytes    |slot |
|------------------------------------|---------|-----|
|bool public locked                  |1        |0    |
|uint256 public ID                   |32       |1    |
|uint8 private flattening            |1        |2    |
|uint8 private denomination          |1        |2    |
|uint16 private awkwardness          |2        |2    |
|bytes32[3] private data[0]          |32       |3    |
|bytes32[3] private data[1]          |32       |4    |
|bytes32[3] private data[2]          |32       |5    |

读取slot5值即可通关

编写攻击脚本[privacy_hack.s.sol](Writeup/awmpy/script/ethernaut/privacy_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/privacy_hack.s.sol:PrivacyHackScript -vvvv --broadcast
```

### 2024.09.07

#### 13. Gatekeeper One

这一题有3道门，需要三道门全部通过才可以通关

第一道门要求`msg.sender != tx.origin`，只需要使用合约而不是EOA调用目标合约即可
第二道门要求gasleft能被8191整除，这个需要在合约中爆破一下，多调用几次目标
第三道门的条件比较多，需要将`tx.origin`转成bytes8`bytes8(uint64(uint160(tx.origin)))`，再使用AND运算将从右往左数的3-4bytes修改掉，即可通过第三关`bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF`

编写攻击合约[gatekeeper_one_hack.sol](Writeup/awmpy/src/ethernaut/gatekeeper_one_hack.sol)
编写攻击脚本[gatekeeper_one_hack.s.sol](Writeup/awmpy/script/ethernaut/gatekeeper_one_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/gatekeeper_one_hack.s.sol:GatekeeperOneHackScript -vvvv --broadcast
```

#### 14. Gatekeeper Two

这一道题同样有三道门

第一道门还是要求`msg.sender != tx.origin`，只需要使用合约而不是EOA调用目标合约即可
第二道门中有`extcodesize`和`assembly`，`extcodesize`是一种opcode，用来取指定地址的合约大小，单位为bytes，第二道门的检查需要确保`extcodesize(calller())`的值等于0
第一道门要求caller必须是合约，第二道门又要求caller的`extcodesize`必须是0，唯一能满足条件的只有不包含runtime code的合约
runtime code是最终留在区块链上执行的代码，可以被不断重复调用、执行，creation code是执行一次初始化合约的状态后就消失，因此我们只需要把攻击代码写到`construst`中，不写其他的func，即可通过第二道门
第三道门中有一个`^`，代表bitwise的XOR异或运算，需要将`uint64(_gatekey)`与`type(uint64).max`位置交换，就能取得正确的key，需要将原本的`msg.sender()`改成`address(this)`也就是攻击合约

``` bash
uint64 key = uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ type(uint64).max);
```

编写攻击合约[gatekeeper_two_hack.sol](Writeup/awmpy/src/ethernaut/gatekeeper_two_hack.sol)
编写攻击脚本[gatekeeper_two_hack.s.sol](Writeup/awmpy/script/ethernaut/gatekeeper_two_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址，脚本中只需要new攻击合约即可，因为攻击合约只实现了`construst`

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/gatekeeper_two_hack.s.sol:GatekeeperTwoHackScript -vvvv --broadcast
```

#### 15. Naught Coin

这一道题需要把自己的余额清空

`lockTokens`中限制了`msg.sender`不能是player，因此需要通过攻击合约来发送转账请求

攻击思路:
player将所有代币授权给攻击合约，攻击合约调用`transferFrom`函数把player的代币清空，from写player地址，to写攻击合约本身或其他地址

编写攻击合约[naught_coin_hack.sol](Writeup/awmpy/src/ethernaut/naught_coin_hack.sol)
编写攻击脚本[naught_coin_hack.s.sol](Writeup/awmpy/script/ethernaut/naught_coin_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/naught_coin_hack.s.sol:NaughtCoinHackScript -vvvv --broadcast
```

#### 16. Preservation

这一题有两个合约`Preservation`与`LibraryContract`，两个合约之间使用了`delegatecall`

`Preservation`中有4个storage变量，timeZone1Library位于slot0，timeZone2Library位于slot1，owner位于slot2，storedTime位于slot3
`LibraryContract`中只有1个storage变量，storedTime位于slot0
当调用`Preservation`的`setFirstTime`函数时，会`delegatecall`到`LibraryContract`的`setTime`方法来修改storedTime变量
漏洞就出现在两个合约的slot0所存储的变量不同，`Preservation`在进行`delegatecall`到`LibraryContract`的`setTime`时修改的是本地的slot0，也就是timeZone1Library
这样就可以用攻击合约调用`setFirstTime`函数来将timeZone1Library改成攻击合约
改成攻击合约后再次调用`setFirstTime`函数，就会调用到攻击合约的`setTime`，可以在攻击合约的`setTime`中修改owner，因为是`delegatecall`，此处修改的也是`Preservation`的owner，以此获取合约控制权
第一次调用`setFirstTime`调用链

``` bash
EOA ==> AttackContract ==> Preservation ==> LibraryContract ==> setTime ==> 篡改Preservation的timeZone1Library为AttackContract
```

第二次调用`setFirstTime`调用链

``` bash
EOA ==> AttackContract ==> Preservation ==> AttackContract ==> settime ==> 篡改Preservation的owner为player
```

编写攻击合约[preservation_hack.sol](Writeup/awmpy/src/ethernaut/preservation_hack.sol)
编写攻击脚本[preservation_hack.s.sol](Writeup/awmpy/script/ethernaut/preservation_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/preservation_hack.s.sol:PreservationHackScript -vvvv --broadcast
```

### 2024.09.08

#### 17. Recovery

这一题需要找出新创建的`SimpleToken`合约地址，可通过etherscan或自己算
然后调用合约的`destroy`方法即可

使用`keccack256(RLP_encode(address, nonce))`可计算出合约地址，是由'creator address'及其nonce经过RLP编码后，在经过keccack256算法取最右边160bits

address：是合约创建者的地址，也就是`Recovery`的地址
nonce：是合约发送的总交易数量，如果是EOA会从0开始计算，而合约是从1开始计算，假设`Recovery`是新创建的合约，那么nonce值就是1

通过以下算法计算新合约地址

``` bash
address newAddress = address(uint160(uint256(keccak256(abi.encodePacked(
    bytes1(0xd6),
    bytes1(0x94),
    challengeInstance,
    bytes1(0x01)
)))));
```

编写攻击合约[recovery_hack.sol](Writeup/awmpy/src/ethernaut/recovery_hack.sol)
编写攻击脚本[recovery_hack.s.sol](Writeup/awmpy/script/ethernaut/recovery_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/recovery_hack.s.sol:RecoveryHackScript -vvvv --broadcast
```

#### 18. MagicNumber

此次目标是部署一个小于10 opcode的合约
如果按照往常写solidity合约后部署，即使只有1个函数，也会超过10opcode，因此我们要想办法写出一个最轻量的bytescode合约

bytescode会分成creation code和runtime code，由于检查是否通关是通过EXTCODESIZE，所以我们的runtime code不能大于10个opcode。接下来分成creation code和runtime code两部分来分析

##### Runtime Code

solver需要42作为返回值，42对应的十六进制数字是0x2a
return对应的opcode是RETURN，但RETURN(p, s)需要两个参数，p是返回值在内存中的位置，s是返回值的大小。这意味着0x2a需要先存到内存中才能被返回，因此还需要第二个opcode MSTORE(p, v)。MSTORE的参数中p是存储值在内存中的位置，v是存储值。而为了得到RETURN和MSTORE这两个opcode所需要的参数，还需要利用PUSH1这个opcode来把参数推入stack，所以Runtime Code会使用到的opcode共有3个

| OPCODE | NAME   |
|--------|--------|
| 0x60   | PUSH1  |
| 0x52   | MSTORE |
| 0xf3   | RETURN |

接着就按照顺序开始：
1. 先用MSTORE将42（0x2a）存储到内存中

EVM在执行opcode时，基本上参数都是从stack最上方pop出的值，由于stack的特性是后进先出，所以在执行MSTORE(p, v)时，需要先被PUSH1进入stack的参数是v，也就是0x2a
然后要被PUSH1的参数才是p，因为没有要求要放在内存的哪个位置，所以可以随意挑选，但通常0x80之前的位置都有其他用途，比如0x40就是free memory pointer，所以default从0x80开始存储，就选择0x80用来存储p

| OPCODE | DETAIL |
|--------|--------|
| 602a   | push 0x2a in stack. Value(v) param to MSTORE(0x60) |
| 6080   | push 0x80 in stack. Position(p) param to MSTORE    |
| 52     | store value,v=0x2a in position p=0x80 in memory    |

2. 再用RETURN将42(0x2a)返回

由于前面用MSTORE将42写入了memory，现在就可以使用RETURN将42返回
RETURN(p, s)也需要两个参数，需要先被PUSH1进入stack的是s(返回值的大小)，因为返回值42是uint256，大小为32bytes，也就是0x20
然后需要被PUSH1进入stack的值是p(返回值在memory中的位置)，也就是0x80

| OPCOE | DETAIL |
|-------|--------|
| 6020  | push 0x20 in stack. Size(s) param to RETURN(0xf3) |
| 6080  | push 0x80 in stack. Postion(p) param to RETURN    |
| f3    | RETURN value=0x2a, size=0x20, position=0x80       |

最后将上述两个步骤的opcode合并到一起就是：602a60805260206080f3，刚好组成了10个bytes大小的Runtime Code

##### Creation Code

接下来要组存Creation Code来讲Runtime Code部署到链上。Creation Code实际的操作是先把Runtime Code加载到memory中，再将其返回给EVM，随后EVM会把602a60805260206080f3这串bytescode存储到链上，而这部分不需要我们处理

将Runtime Code代码加载到memory中的opcode是CODECOPY(d,p,s)，需要3个参数，d代表memory中复制代码的目标位置，p代表Runtime Code的当前位置，s则代表以byte为单位的代码大小。而返回给EVM同样是使用RETURN(p,s)，因为这两个opcode都有参数所以同样也需要用PUSH1把参数推入到stack中。

因此Creation Code会用到3个opcode
| OPCODE | NAME |
|--------|------|
| 0x60   | PUSH1 |
| 0xf3   | RETURN |
| 0x39   | CODECOPY |

接着就按照顺序开始：
1. 先用CODECOPY将Runtime Code复制到memory中

同样基于EVM Stack的后进先出原则，所以在执行CODECOPY(d, p, s)时需要先PUSH1进入stack的值是s(代码大小，以bytes为单位)，也就是Runtime Code的大小10bytes，所以s值等于0x0a

第二个要被PUSH1的参数是p，也就是Runtime Code的位置。由于Creation Code还未完成，无法确定Runtime Code的真正位置，先留空

第三个要被PUSH1的参数是d，也就是memory中复制代码的目标位置，直接选用0x00这个位置即可，因为当EVM执行到COPYCODE代表已经到了程序执行尾端，所以这时编译器已不需要之前提到的0x40 free memory pointer了

| OPCODE | DETAIL |
|--------|--------|
| 600a   | push 0x0a in stack. size of runtime code 10 bytes |
| 60??   | push ??(un) unknown in stack. Position(p) param to COPYCODE |
| 6000   | push 0x00 in stack. Destination(d) param to COPYCODE |
| 39     | COPYCODE |

2. 再用RETURN将Runtime Code返回给EVM

由于前面通过COPYCODE把Runtime Code写入到了memory中，接下来使用RETURN把Runtime Code返回给EVM

RETURN(p, s)需要两个参数，需要先被PUSH1进入stack的是s(返回值的大小)，因为返回值大小就是Runtime Code的大小10bytes，因此s的值是0x0a
然后需要被PUSH1进入stack的值是p(返回值在memory中的位置)，也就是0x00

| OPCOE | DETAIL |
|-------|--------|
| 600a  | push 0x0a in stack. Size(s) param to RETURN(0xf3) |
| 6000  | push 0x00 in stack. Postion(p) param to RETURN    |
| f3    | RETURN size=0x0a, position=0x00                   |

再将上述两个步骤的opcode组合起来就是：600a60??600039600a6000f3，组成12个bytes大小的Creation Code，知道了Creation Code的大小就可以把??给填上，也就是0x0c，因此最终的opcode就是：600a600c600039600a6000f3

再把Creation Code与Runtime Code拼接在一起就是

600a600c600039600a6000f3(Creation Code) + 602a60805260206080f3(Runtime Code) = 600a600c600039600a6000f3602a60805260206080f3

这就是我们要部署的合约


编写攻击合约[magic_number_hack.sol](Writeup/awmpy/src/ethernaut/magic_number_hack.sol)
编写攻击脚本[magic_number_hack.s.sol](Writeup/awmpy/script/ethernaut/magic_number_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/magic_number_hack.s.sol:MagicNumberHackScript -vvvv --broadcast
```


### 2024.09.09

<!-- Content_END -->
