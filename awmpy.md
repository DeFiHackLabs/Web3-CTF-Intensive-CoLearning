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

#### 19. AlienCodex

合约中继承的Ownable[../helpers/Ownable-05.sol](https://github.com/OpenZeppelin/openzeppelin-test-helpers/blob/master/contracts/Ownable.sol)

Ownable合约中第一个变量`address private _owner;`，想办法改掉这个值就可以获得合约控制权，被继承的合约中storage variable会存储在原合约之前，所以`_owner`是存储在slot 0这个位置

合约是用了0.5.0版本，小于0.8.0，可能存在overflow/underflow漏洞，要想修改slot 0就需要利用这个漏洞(之前的挑战中有使用vm.load读取过slot 0的数值破解key，还有利用漏洞替换掉slot 0存储的合约)，本次需要利用合约中的array溢出来达到修改slot 0的目的

合约中`record`、`retract`和`revise`都有contacted这个modifier，其中对contact值做了判断，因此需要先调用`makeContact`来将contact值改为true

##### Dynamic Array存储方式

假设有个未知长度的array`uint256[] c`，变量c所在的位置存储的值是`c.length`，而其中的元素会从`keccak256(slot)`开始，假设c存储在slot 2，也就是说其中元素c[0]是存储在`keccak256(2)`，c[1]存储在`keccak256(2) + 1`以此类推

##### Array Underflow漏洞

Solidity版本小于0.8.0意味着没有溢出检查，可以通过调用`retract()`使用当前长度为0的codex减去1，它的长度会因为0-1发生下溢而变成一个很大的值(2**256-1)
有了这么长的codex之后，它的index能够覆盖所有的slot(2**256-1)，也就是说此时codex的长度与slot的总数相同都是`(2**256-1)`，我们就可以通过调用revise来修改codex中的任意值，也就可以修改任意slot的值
但又因为codex的元素存储是从`keccak256(2)`开始，因此需要算出正确的slot 0在codex的中index

| Slot | Data |
|------|------|
| 0    | owner address |
| 1    | codex.length  |
| ...  | ... |
| p+0  | codex[p+0 - p] |
| p+1  | codex[p+1 - p] |
| ...  | ... |
| 2^256-2 | codex[2^256-2 - p] |
| 2^256-1 | codex[2^256-1 - p] |
| 0    | codex[2^256-0 - p] |

假设codex[0]位于slot p，那么slot 0就对应的index就是`2^256-p`，因为codex存储在slot 0，p值就是`keccak256(1)`，slot 0对应的index就是`2^256 - keccak256(1)`
有了正确的index，再把msg.sender写入这个这个index就可以获取合约所有权

攻击步骤：
1. 调用makeContact把contact值改为true
2. 调用retract把codex长度溢出
3. 计算slot 0在codex中的index，调用revise写入msg.sender


编写攻击合约[alien_codex_hack.sol](Writeup/awmpy/src/ethernaut/alien_codex_hack.sol)
编写攻击脚本[alien_codex_hack.s.sol](Writeup/awmpy/script/ethernaut/alien_codex_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/alien_codex_hack.s.sol:AlienCodexHackScript -vvvv --broadcast
```

#### 20. Denial

这一关比较简单，用到了之前用到过的DOS攻击和Re-entrancy攻击，最终目标是让owner在调用withdraw的时候无法正常提款

先调用`setWithdrawPartner`成为partner，再通过在攻击合约实现receive的方式循环调用withdraw，让owner无法获得分成即可

编写攻击合约[denial_hack.sol](Writeup/awmpy/src/ethernaut/denial_hack.sol)
编写攻击脚本[denial_hack.s.sol](Writeup/awmpy/script/ethernaut/denial_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/denial_hack.s.sol:DenialHackScript -vvvv --broadcast
```

#### 21. Shop

这一关类似于Elevator，只不过额外做了view限制，无法直接修改状态，但可以利用攻击合约中的函数根据isSold状态判断来返回不同的值

当isSold为True，则返回1，isSold为False则返回100
这样就可以用100通过第一个判断，用1实现购买

编写攻击合约[shop_hack.sol](Writeup/awmpy/src/ethernaut/shop_hack.sol)
编写攻击脚本[shop_hack.s.sol](Writeup/awmpy/script/ethernaut/shop_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/shop_hack.s.sol:ShopHackScript -vvvv --broadcast
```

### 2024.09.10

#### 22. Dex

这一关的漏洞出现在`getSwapPrice()`函数中，由于其中除法会出现向下取整的问题
`amount * IERC20(to).balanceOf(address(this)))/IERC20(from).balanceOf(address(this)));`
只需要不停的swap手动的全部代币，就可以掏空池子

| STEP   | DEX token1 | DEX token2 | Player token1 | Player token2 |
|--------|--------|--------|--------|--------|
|  Init  |   100  |  100   |    10  |   10   |    
|Swap 1  |   110  |   90   |     0  |   20   |    
|Swap 2  |    86  |  110   |    24  |    0   |    
|Swap 3  |   110  |   80   |     0  |   30   |    
|Swap 4  |    69  |  110   |    41  |    0   |
|Swap 5  |   110  |   45   |     0  |   65   |   
|Swap 6  |     0  |   90   |   110  |   20   |

在执行第6次swap时，池子中只剩45个Token2，所以我们只需要换45个就可以

编写攻击合约[dex_hack.sol](Writeup/awmpy/src/ethernaut/dex_hack.sol)
编写攻击脚本[dex_hack.s.sol](Writeup/awmpy/script/ethernaut/dex_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/dex_hack.s.sol:DexHackScript -vvvv --broadcast
```

#### 23. DexTwo

这一关与上一关的合约几乎一模一样，只不过去除了只能token1和token2互换的限制，并且要求清空token1和token2
只需要自己发行一个ERC20的代币Evil，然后去换token1和token2即可

|   Step  | DEX token1 | DEX token2 | DEX WETH | Player token1 | Player token2| Player WETH |
| --------|--------|-------|-------|--------|-------|------|
|   Init  |   100  |  100  |  100  |    10  |   10  |  300 |
| Swap 1  |     0  |  100  |  200  |   110  |   10  |  200 |
| Swap 2  |     0  |    0  |  400  |   110  |  110  |    0 |

编写攻击合约[dextwo_hack.sol](Writeup/awmpy/src/ethernaut/dextwo_hack.sol)
编写攻击脚本[dextwo_hack.s.sol](Writeup/awmpy/script/ethernaut/dextwo_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/dextwo_hack.s.sol:DexTwoHackScript -vvvv --broadcast
```

### 2024.09.11

#### 24. PuzzleWallet

这个挑战是一个代理合约，通过`PuzzleProxy`代理对`PuzzleWallet`的请求，通过`delegatecall`转发请求，通关目标是获取`PuzzleProxy`合约的owner权限

通过`delegatecall`转发的请求，对被调用的合约所做的修改都会保存在Proxy合约中
在实现可升级合约时，如果没能保证slot排列相同，就会发生更新一个合约存储变量时错误的更新了另一个合约对应slot的变量

slot排列:
| Slot | PuzzleProxy  | PuzzleWallet |
|------|--------------|--------------|
| 0    | pendingAdmin | owner        |
| 1    | admin        | maxBalance   |

因为我们需要变成`PuzzleProxy`的管理员，所以需要想办法把slot1改成我们的钱包地址，slot1上有`maxBalance`和`admin`两个存储变量，通过修改`maxBalance`就可以覆盖掉`admin`，这就是我们的最终目标了

可以修改`maxBalance`变量值只有两个地方`init`函数和`setMaxBalance`函数，`init`函数中要求`maxBalance`为0才能执行，但`init`已被执行过，这个值不是0，只能看`setMaxBalance`函数能否利用

`setMaxBalance`函数要求调用者在白名单中，且合约的balance为0

目前的目标就变成了：
1. 让自己加入白名单
`addToWhitelist`函数要求是owner才能将地址加入白名单
而我们通过错误的slot排列可以发现，更新`PuzzleProxy`的`pendingAdmin`值就可以把`PuzzleWallet`的`owner`改掉，这样就能顺利拿到`PuzzleWallet`的owner权限，并把自己的地址加入到白名单中
2. 清空合约余额
`execute`是唯一一个可以向其他地址进行`call()`并带有一些value的函数，我们可以利用这个函数把合约内所有的钱转走，但它要检查`msg.sender`是否有足够的余额来操作，必须要想办法把`balances[msg.sender]`加到大于或等于合约余额，才能把合约内所有钱转走
`deposit`函数可以增加`msg.sender`的余额，调用`deposit`会发生两件事：`balances[msg.sender]`增加和合约的balance增加，合约内部署时已经有了0.001ether
假设调用`deposit`存入0.001ether，会发生`balances[msg.sender]`变为0.001，合约的balance变为0.002，还是无法满足`balances[msg.sender]`大于等于合约balance，因此需要想办法让`balances[msg.sender]`增加两次0.001，而合约balance只增加一次0.001，这样就可以让`balances[msg.sender]`有合约balance都是0.002，这样才能调用`execute`把合约balance清空

目前的目标就变成了：调用`deposit`让`balances[msg.sender]`增加两次0.001，而合约balance只增加0.001

要实现这个目标需要借助`PuzzleWallet`中的`multicall`函数，它允许用户在单笔交易中多次调用一个函数，来实现节省gas的目的

``` bash
function multicall(bytes[] calldata data) external payable onlyWhitelisted {
    bool depositCalled = false;
    for (uint256 i = 0; i < data.length; i++) {
        bytes memory _data = data[i];
        bytes4 selector;
        assembly {
            selector := mload(add(  , 32))
        }
        if (selector == this.deposit.selector) {
            require(!depositCalled, "Deposit can only be called once");
            // Protect against reusing msg.value
            depositCalled = true;
        }
        (bool success, ) = address(this).delegatecall(data[i]);
        require(success, "Error while delegating call");
    }
}
```

如果能够在同一笔交易中使用0.001个以太币调用`deposit`两次，这意味着只提供了一次0.001个以太币，玩家的余额 `balances[msg.sender]`将从0变为0.002，但实际上，由于我们在同一笔交易中这样做了，我们的存款金额仍将为0.001
但在`multicall`函数中利用`depositCalled`变量限制了`deposit`只能被调用一次

`multicall`可以调用`PuzzleWallet`的任意函数，包括`multilcall`本身
这样就给我们提供了机会，可以在一个`multicall`的调用中再嵌套`multicall`，而每个`multicall`的`depositCalled`都是单独计算的，这样就能实现在一个交易中调用两次`deposit`

逻辑示意：

``` bash
multicall = [
    multicall: [deposit],
    multicall: [deposit]
]

OR

multicall = [
    multicall: [deposit],
    deposit
]
```

到目前为止，完整的攻击路径已经出现：
1. 调用`PuzzleProxy`的`proposeNewAdmin`函数传入player地址，达到修改`PuzzleWallet`的owner的目的，获取`PuzzleWallet`的owner权限
2. 调用`PuzzleWallet`的`addToWhitelist`，传入player地址，把自己加入到白名单中
3. 调用`PuzzleWallet`的`multicall`将组装好的data和0.001ether发送过去，达到`balances[msg.sender]`等于合约balance的目的
4. 调用`PuzzleWallet`的`execute`将合约内的0.002ether转到player地址
5. 调用`PuzzleWallet`的`setMaxBalance`将`maxBalance`的值改为player地址，同时因为`maxBalance`和`PuzzleProxy`的`admin`变量都在slot1存储，此时也获取了`PuzzleProxy`合约的admin权限

将合约代码复制到[puzzle_wallet.sol](Writeup/awmpy/src/ethernaut/puzzle_wallet.sol)
编写攻击脚本[puzzle_wallet_hack.s.sol](Writeup/awmpy/script/ethernaut/puzzle_wallet_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/puzzle_wallet_hack.s.sol:PuzzleWalletHackScript -vvvv --broadcast
```

### 2024.09.12

#### 25. Motorbike

本关的目标是在合约`Engine`上调用`selfdestruct`让代理合约无法再使用

在Dencun升级之后，在[EIP-6780](https://eips.ethereum.org/EIPS/eip-6780)中更改了`SELFDESTRUCT`操作码的功能，新功能只是将账户中的所有以太币发送到目标，但在创建合约的同一交易中调用`SELFDESTRUCT`时，当前行为将被保留
因此要将创建instance合约和实现`selfdestruct`在同一交易中实现才行

[Dencun升级后解法](https://github.com/Ching367436/ethernaut-motorbike-solution-after-decun-upgrade)

背景知识：
这一关中使用了`UUPS(Universal Upgradeable Proxy Standard)`的代理模式，上一个关中使用的是`TPP(Transparent Proxy Pattern)`的代理模式
UUPS与TPP相比主要有几个区别：
1. UUPS的升级函数是实现在`Logic Contract`中，而不是`Proxy Contract`中
2. UUPS不会在每次call的时候都去检查调用者身份，而只在升级时检查

代理合约中最容易出问题的两个点就是：`Storage collision`和`initialization`
上一关中就利用了两次`Storage collision`漏洞来获取admin权限，为了避免`Storage collision`漏洞发生，ERC-1967规定了重要变量的storage slot位置，例如Logic、Admin、Beacon等，通过对字符串`eip1967.proxy.xxx`使用`keccak256`加密后，把得到的结果当做slot index，将xxx变量的值放到这个很远很大的slot中，以此大幅度降低碰撞的风险

初始化`initialization`是指代理合约的初始化，一般在部署合约时都会通过`constructor`设置一些初始化变量，但代理合约的情况下，如果在`Logic Contract`中使用`constructor`来初始化，变量会保存在`Logic Contract`中，就不符合变量都保存在`Proxy Contract`中的设计，因此会在`Logic Contract`中定义一个`initialize`函数来做一些初始化的工作，并且使用一个`initialized`来确保`initialize`只被调用一次

在一关中`Proxy Contract`是Motorbike，`Logic Contract`是Engine，并且使用了ERC-1967来防止`Storage collision`

目标是调用Engine的`selfdestruct`函数让其自毁，但在Engine中没有实现这个函数，就需要考虑升级`Logic Contract`让其变成攻击合约，在攻击合约中实现一个`selfdestruct`

Engine实现了一个`upgradeToAndCall`函数来升级合约，但是限制了`msg.sender == upgrader`

目标就变成了让自己成为`upgrader`，Engine中只有`initialize`函数可以设置`upgrader`，因为这一关使用了ERC-1967，`Proxy Contract`与`Logic Contract`没有相似的slot排布，无法像上一关中直接修改`upgrader`的值，只能通过`initialize`来更新`upgrader`

`initialize`函数有一个`initializer`装饰器来进行对`initializer`的校验，确保合约只被初始化一次，但由于`Proxy Contract`调用`initialize`是通过`delegatecall`，会导致`initializer`是存储在`Proxy Contract`中，`Logic Contract`中的`initializer`仍是未初始化状态，就可以绕过`Proxy Contract`直接调用`initialize`，这样就可以让`msg.sender`成为`upgrader`

综上所述，攻击思路如下：
1. 创建一个实现了调用`selfdestruct`函数的攻击合约
2. 读取`_IMPLEMENTATION_SLOT`，并计算出Engine合约的地址
3. 调用Engine的`initialize`函数来成为`upgrade`
4. 调用Engine的`upgradeToAndCall`来将`Logic Contract`升级为攻击合约，并调用升级后共计合约进行自杀

编写攻击合约[motorbike_hack.sol](Writeup/awmpy/src/ethernaut/motorbike_hack.sol)
编写攻击脚本[motorbike_hack.s.sol](Writeup/awmpy/script/ethernaut/motorbike_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/motorbike_hack.s.sol:MotorbikeHackScript -vvvv --broadcast
```

#### 26. Double Entry Point

这一关提供了两个ERC20的合约`LegacyToken(LGT)`和`DoubleEntryPoint(DET)`以及一个金库合约`CryptoVault`，金库内存有LGT和DET各100个，但金库存在BUG可能会被人把金库中的代币转走，我们需要想办法保护合约内的代币

LGT合约：
在LGT合约中重写了ERC20默认的`transfer`函数，检查`delegate`地址为0的情况，就从ERC20中调用`transfer`函数，如果`delegate`地址不为0，就调用`delegate.delegateTransfer`函数

LGT中还实现了`delegateToNewContract`函数，用来设置`delegate`的值，且这个函数有`onlyOwner`装饰器，只能由owner来设置`delegate`，且`newContract`需要是`DelegateERC20`

DET合约：
合约继承了`DelegateERC20`，满足作为LGT的`delegateToNewContract`参数的条件，因此LGT中的`delegate`就是DET合约

构造函数中定义了`delegatedFrom`、`forta`、`player`、`cryptoVault`地址，并且给`CryptoVault`mint了100个DET

装饰器`onlyDelegateFrom`限制了`msg.sender`只能是设置为`LegacyToken`地址的`delegatedFrom`合约，这意味着使用这个装饰器的函数只能被`LegacyToken`来调用

装饰器`fortaNotify`是Forta机器人使用的，他会先把`forta.botRaisedAlerts(detectionBot)`执行的结果存储起来，调用一次`forta.notify(player, msg.data)`来给机器人发送通知，接着正常执行函数功能，之后再调用一次`forta.botRaisedAlerts(detectionBot)`，并将notify前后两次的结果进行比较，如果第二次数量大于第一次，就revert整个交易，这个装饰器只应用于`delegateTransfer`函数

函数`delegateTransfer`设置了`fortaNotify`和`onlyDelegateFrom`两个装饰器，说明这个函数只允许`LegacyToken`来调用，并且可以由bot来检查交易是否合理，此函数会调用`_transfer`函数，将value数量的代表从`origSender`转到`to`

CryptoVault合约：
函数`setUnderlying`设置了`underlying`的代币地址，在这里是DET的地址，且只能调用一次，也就是说我们无法再修改

函数`sweepToken`将ERC20的代币地址作为函数参数，并确保它不等于`underlying`也就是DET，然后调用了新传入的代币的`transfer`函数，将金库中所有的代币都转给`sweptTokensRecipient`
`sweptTokensRecipient`地址是在构造函数中设置的，不受我们控制

攻击思路：
假设我们是攻击者，唯一能把`CryptoVault`合约中代币转走的函数是`sweepToken`，但由于限制了token不能是DET，只能考虑给这个函数传入LGT的地址这样就会调用LGT的`transfer(sweptTokensRecipient, CryptoVault's Total Balance)`函数(重写过的)

最终会调用到`delegate.delegateTransfer(to, value, msg.sender)`，也就是`DoubleEntryPoint.delegateTransfer(sweptTokensRecipient, CryptoVault's Total Balance, CryptoVault's Address)`

现在流程走到了DET的`delegateTransfer`函数中，`onlyDelegateFrom`的限制会被通过，因为`msg.sender`是LGT，这样就能够绕过`sweepToken`的限制，而把所有的DET给转走

具体操作：

``` bash
// ethernaut提供的instance地址是DET的地址，可以通过`cryptoVault`变量查到`CryptoVault`的合约地址，通过`delegatedFrom`来获取LGT的地址

vault = await contract.cryptoVault()

// 检查DET余额 (100 DET)
await contract.balanceOf(vault).then(v => v.toString()) // '100000000000000000000'

// 查询LGT的Address
legacyToken = await contract.delegatedFrom()

// 组装通过sweepToken转走DET的Data
sweepSig = web3.eth.abi.encodeFunctionCall({
    name: 'sweepToken',
    type: 'function',
    inputs: [{name: 'token', type: 'address'}]
}, [legacyToken])

// 发送攻击请求
await web3.eth.sendTransaction({ from: player, to: vault, data: sweepSig })

// 再次检查DET余额 (0 DET)
await contract.balanceOf(vault).then(v => v.toString()) // '0'
```

防御思路：
Forta合约：
函数`setDetectionBot`用来设置机器人的地址，需要利用这个函数把机器人设置为自己的机器人地址

函数`notify`中调用了机器人的`handleTransaction`函数来检查calldata，因此我们需要在机器人中实现一个`handleTransaction`函数并设置一些条件来触发告警，此函数会在DET合约中的`fortaNotify`装饰器中被调用，也就是用来触发通知

函数`raiseAlert`会将`msg.sender`的告警数加1

还有个`IDetectionBot`的接口，其中有`handleTransaction`函数名标签

``` bash
攻击路径:
CryptoVault.sweepToken(LGT) ==> LGT.transfer(sweptTokensRecipient, CryptoVault's Token Balance) ==> DET.delegateTransfer(sweptTokensRecipient, CryptoVault's Total Balance, CryptoVault's Address)
```

调用到`delegateTransfer`函数时，装饰器`fortaNotify`会把接受到的`msg.data`发送给机器人的`handleTransaction`来处理，因此需要实现一个带有`handleTransaction`函数的机器人，并检查`msg.data`中的`origSender`是不是`CryptoVault`的地址

解析calldata：

在`fortaNotify`中`msg.data`是`function delegateTransfer(address to, uint256 value, address origSender)`

在`notify`中调用了`handleTransaction`函数，这里会改变`msg.data`

到了`handleTransaction`函数中，`msg.data`就变成了`function handleTransaction(address user, bytes calldata msgData) external`，其中的第二个参数`bytes calldata msgData`才是我们想要的原本的`msg.data`，需要从中提取出`origSender`

机器人看到的calldata数据排列：

| Position | Bytes Length | Var Type | Value |
|----------|--------------|----------|-------|
| 0x00     | 4            | bytes4   | Function selector of `handleTransaction(address,bytes) == 0x220ab6aa` |
| 0x04     | 32           | address  | user address |
| 0x24     | 32           | uint256  | msgData 的偏移量 |
| 0x44     | 32           | uint256  | msgData 的长度 |
| 0x64     | 4            | bytes4   | Function selector of `delegateTransfer(address,uint256,address) == 0x9cd1a121` |
| 0x68     | 32           | address  | to 参数地址 |
| 0x88     | 32           | uint256  | value 参数 |
| 0xA8     | 32           | address  | origSender 参数地址 |
| 0xC8     | 28           | bytes    | 根据编码字节的 32 字节参数规则进行零填充 |

可通过`cast sig "handleTransaction(address,bytes)"`获取函数签名

从表中可以看出，前半部分是函数`handleTransaction`，后半部分是`delegateTransfer`，其中就有需要的`origSender`数据

编写攻击合约[double_entry_point_hack.sol](Writeup/awmpy/src/ethernaut/double_entry_point_hack.sol)
编写攻击脚本[double_entry_point_hack.s.sol](Writeup/awmpy/script/ethernaut/double_entry_point_hack.s.sol)，其中合约地址使用ethernaut提供的合约地址

执行脚本发起攻击

``` bash
forge script  --rpc-url https://1rpc.io/holesky script/ethernaut/double_entry_point_hack.s.sol:DoubleEntryPointHackScript -vvvv --broadcast
```

### 2024.09.13

<!-- Content_END -->
