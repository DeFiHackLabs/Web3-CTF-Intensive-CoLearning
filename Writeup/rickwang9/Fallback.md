需要修改owner，显然正常渠道无法直接修改。

非正常的就是receive
```
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
```
给合约转账，且没有指定具体函数，就会触发receive

receive的逻辑是曾经做过贡献，并且这次转钱了，就修改owner。

```
    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }
```
那攻击逻辑就是 
1. contribute，转账金额 < 0.001 ether
2. call转账， >= 1 wei 即可
3. 调用withdraw 完成攻击


