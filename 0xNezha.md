---
timezone: Asia/Shanghai
---

> 请在上边的 timezone 添加你的当地时区，这会有助于你的打卡状态的自动化更新，如果没有添加，默认为北京时间 UTC+8 时区
> 时区请参考以下列表，请移除 # 以后的内容

---

# 0xNezha

1. 自我介绍
[0x哪吒](https://x.com/0xNezha).
2. 你认为你会完成本次残酷学习吗？
hmm... 希望这次不要分心 XD

## Notes

<!-- Content_START -->

### 2024.08.29

配置相关环境，使用 Foundry Cast 与合约交互，完成 Ethernaut 之 [00_Hello Ethernaut](./Writeup/0xNezha/Ethernaut/00_Hello%20Ethernaut.md) 

### 2024.08.30
在以太坊智能合约中，receive 函数是一个特殊的函数，用于接收以太币。当合约地址接收到以太币时，这个函数会被自动调用。[01_Fallback](./Writeup/0xNezha/Ethernaut/01_Fallback.md) 

### 2024.08.31
在 0.4.22 版本之前, 构造函数被定义为合约的同名函数（该语法在0.5.0之后弃用）。合约作者准备把Fal1out() 作为 合约 Fallout 的构造函数，以在合约部署时调用。但很不巧，笔误写错了，导致任何人都可以调用。[02_Fallout](./Writeup/0xNezha/Ethernaut/02_Fallout.md)

### 2024.09.01
周日休息XD

### 2024.09.02
一个猜硬币函数，输入参数是 true/false , 判断逻辑是：区块hash 与 FACTOR 进行除法运算，结果等于 1 则 side 这个变量为 true，不等于 1 则变量为 false。
判断输入参数是否等于函数的运算结果。相等则加 1 分，不相等则分数清零。
通过编写一个有着相同运算逻辑的合约，对结果进行提前运算。然后调用目标合约的函数，把运算结果输入进去，实现每次都猜中。[03_CoinFlip](./Writeup/0xNezha/Ethernaut/03_CoinFlip/src/CoinFlip_exp.sol)

### 2024.09.03
changeOwner(address _owner) 函数，仅当 tx.origin != msg.sender 的时候，才可以修改 owner。tx.origin 是 EOA 地址，而 msg.sender 是调用该合约的地址，当 EOA 直接调用该合约时，二者相等。这里我们部署一个“中间人”合约来调用该合约，那么 tx.origin 就是你的 EOA 地址， msg.sender 就是“中间人”的地址，从而实现  tx.origin != msg.sender 。[04_Telephone](./Writeup/0xNezha/Ethernaut/04_Telephone/src/Telephone_exp.sol)

### 2024.09.04
balances[msg.sender] -= _value 这里没有做安全限制，我们的初始余额是20，如果用它减去 21（向别人转账 21），则会发生数据下溢，得到一个天文数字。[05_Token](./Writeup/0xNezha/Ethernaut/05_Token.md)
 

### 2024.09.05
外部地址 A 通过 合约 B 来 delegatecall 合约 C ，实现在 B 的上下文环境中运行 C 的代码，进而修改 B 的数据。另外，如果调用 B 合约时 B 合约中没有任何匹配的函数时，会触发 B 的 fallback 函数。[06_Delegation](./Writeup/0xNezha/Ethernaut/06_Delegation.md)

### 2024.09.06
利用自毁函数 selfdestruct()，可以将合约内的余额强行转给任何地址或合约。部署一个带自毁函数合约，然后调用它。 [07_Force](./Writeup/0xNezha/Ethernaut/07_Force/src/Force_exp.sol)

### 2024.09.07
vault 的密码 password 是以 bytes32 private 形式存储在 slot 中。通过合约调用的方式当然无法读取 private 变量，但是我们可以直接读取 slot 里面的数据。 [08_Vault](./Writeup/0xNezha/Ethernaut/08_Vault.md)

### 2024.09.08
周日休息XD

### 2024.09.09
玩家打入更多的 ETH 到合约里，合约就会把这些 ETH 打给旧 King，然后玩家成为新的 King。假如这个玩家是一个合约而且无法接受 ETH 呢？那么这个游戏就玩不下去了。所以我们部署一个无法接收 ETH 的合约：[09_King](./Writeup/0xNezha/Ethernaut/09_King/src/King_exp.sol)

### 2024.09.10
玩家可以通过 donate(address _to) 向目标合约充值 ETH ，通过 withdraw(uint256 _amount) 从目标合约中提取 ETH ，但提取的总量不能超过充值的总量。可以构造一个恶意合约利用重入（Re-entrancy）来多次调用目标合约，将其中的 ETH 提空。[10_ReEntrancy](./Writeup/0xNezha/Ethernaut/10_ReEntrancy/src/ReEntrancy_exp.sol)

### 2024.09.11
玩家需要编写一个合约：1.要实现目标合约接口里的函数 isLastFloor(uint256); 2.isLastFloor(uint256) 这个函数每被调用一次，返回值就要翻转一次，且首次调用返回的时是 false; 3.要调用目标合约的 goTo() 函数。[11_Elevator](./Writeup/0xNezha/Ethernaut/11_Elevator/src/Elevator_exp.sol)

### 2024.09.12
喝多了QAQ

### 2024.09.13
bytes32[3] private data 通过合约调用的方式当然无法读取 private 变量，但是我们可以直接读取 slot 里面的数据。另外， byte32 转换为 byte16 的时候，只会留存高16字节。[12_Privacy](./Writeup/0xNezha/Ethernaut/12_Privacy.md)

### 2024.09.14
本题主要考察 gasleft() 及 Debug 获取准确的 gas 用量，还有不同数据类型转换时数值的变化。[13_GatekeeperOne](./Writeup/0xNezha/Ethernaut/13_GatekeeperOne/13_GatekeeperOne.md)

### 2024.09.15
周日休息XD

### 2024.09.16
完善 13_GatekeeperOne 的 EXP (通过位运算生成 key)。[13_GatekeeperOne](./Writeup/0xNezha/Ethernaut/13_GatekeeperOne/src/GatekeeperOne_exp.sol)

### 2024.09.17
本题主要考察：
1、 extcodesize() 的功能：返回合约部署后的字节码大小。有人用它来判断调用者是否为智能合约，但这是有漏洞的，将操作放到构造函数 constructor() 中可破此法。
2、 abi.encodePacked() 的功能：进行压缩编码。比如把填充的很多0省略，只用1字节来编码uint8类型。这能够让编码数据长度减小很多。压缩编码不能与 EVM 交互，适合进行哈希运算或者存储。
3、 “按位异或” 运算符 ^ 及其运算规则，如“自反性”，也就是 a ^ b ^ a = b 。
[14_GatekeeperTwo](./Writeup/0xNezha/Ethernaut/14_GatekeeperTwo/14_GatekeeperTwo.md)

### 2024.09.18
完善 14_GatekeeperTwo 的 EXP。[14_GatekeeperTwo](./Writeup/0xNezha/Ethernaut/14_GatekeeperTwo/src/GatekeeperTwo_exp.sol)
<!-- Content_END -->
