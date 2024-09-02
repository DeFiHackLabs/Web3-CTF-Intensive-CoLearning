---
timezone: Asia/Shanghai
---

# {blockpanda}

1. 自我介绍 - web3新兵

2. 你认为你会完成本次残酷学习吗？- 会

## Notes

<!-- Content_START -->

### 2024.08.29

学习内容
1.安装foundry  
2.领水 https://www.alchemy.com/faucets/ethereum-sepolia     
  https://faucets.chain.link/sepolia    
  https://faucet.chainstack.com/sepolia-testnet-faucet  
3.Ethernaut CTF - Hello Ethernaut 根据教程完成操作  
4.Ethernaut CTF - 暂未完成  

### 2024.08.30
#### 题目
````
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {
    //公共映射，记录了每个地址捐赠的金额
    mapping(address => uint256) public contributions;
    //公开地址变量，记录合约的拥有者的地址
    address public owner;
    
    //构造函数，合约部署时自动执行，合约部署者设置为初始拥有者。
    //给予部署者 1000 ether 的初始贡献
    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }

    //修饰器确保只有合约拥有者才能执行某些函数,否则弹出提示
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    //捐赠函数，1.require条件为假时，交易回滚，msg.value是随当前交易发送的ETH数量
    //2.更新调用者的捐赠总额
    //3.如果调用者贡献超过当前拥有者，则调用者成为拥有者
    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }

    //允许用户查看自己的贡献总额
    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }

    //只有拥有者可以提现，将所有ETH转移到拥有者
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    //receive函数，接收ETH时触发，要求数量大于0，且之前有捐赠者；调用者成为合约拥有者。
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
````

#### 解题思路

很明显，漏洞在contribute函数，但数量要超过1000ETH，且每次发送小于0.001，实现起来不现实  
那么只能通过receive（）来实现，即直接转账且不附加任何数据  

#### 解题过程  
1.contract.contribute({value: 1}) //首先使贡献值大于0  
2.contract.sendTransaction({value: 1}) //触发fallback函数  
3.contract.owner（）//查看合约拥有者  
4.contract.withdraw() //提现到自己的地址  


### 2024.09.01

- [Ethernaut 第三题](/Writeup/blockpanda/readme.md/09.01-ethernaut第三题.md)
<!-- Content_END -->
