### 第0关：Hello Ethernaut

提示：本题可以在浏览器中完成。但我们这次是要结合 Foundry 来完成 Writeup，所以请先安装好 Foundry，并学习(复习) Foundry 基本操作。 

下面进入正题：

按照页面提示，先在 Chrome 浏览器按下 F12 ，在 console 中输入 await contract.address 得到部署的关卡合约地址 0xA53fCB……078D0


因为这次是在 Arbtrum-Sepolia 操作，所以要找个 Arbtrum-Sepolia 的 RPC 备用 https://sepolia-rollup.arbitrum.io/rpc

本题提示使用 await contract.info() 查看关卡信息。使用 cast 调用 0xA53fCB……078D0 合约的 info() 函数。在终端输入：
 ```shell
cast call 0xA53fCB……078D0 "info()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc
```
返回十六进制字符串: 0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000027596f752077696c6c2066696e64207768617420796f75206e65656420696e20696e666f3128292e00000000000000000000000000000000000000000000000000

 使用 **cast --to-ascii** 翻译一下， 
 ```shell
 cast --to-ascii 0x000000000000000000000000000000000000000000000000000000000000000x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000027596f752077696c6c2066696e64207768617420796f75206e65656420696e20696e666f3128292e00000000000000000000000000000000000000000000000000
 ```
翻译成 ASCII 就是:
'You will find what you need in info1().'

那么我们继续调用 info1()：
 ```shell
cast call 0xA53fCB……078D0 "info1()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc
```
返回十六进制字符串: 
0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002d54727920696e666f3228292c206275742077697468202268656c6c6f22206173206120706172616d657465722e00000000000000000000000000000000000000


翻译成 ASCII 就是:
-Try info2(), but with "hello" as a parameter.

那么我们继续调用 info2(),但是注意，需要传入 "hello" 这个参数：
 ```shell
cast call 0xA53fCB……078D0 "info2(string)" hello --rpc-url=https://sepolia-rollup.arbitrum.io/rpc
```
返回 The property infoNum holds the number of the next info method to call.

继续
 ```shell
cast call 0xA53fCB……078D0 "infoNum()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc
```
得到十六进制数字 2a, 使用 **cast --to-dec 2a** 解析，也就是十进制的 42.然后：

 ```shell
cast call 0xA53fCB……078D0 "info42()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc
```

返回 theMethodName is the name of the next method.继续：

 ```shell
cast call 0xA53fCB……078D0 "theMethodName()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc
```
返回 The method name is method7123949.继续：

 ```shell
cast call 0xA53fCB……078D0 "method7123949()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc
```
返回 If you know the password, submit it to authenticate().

那么 password 是什么呢？ 回想到题目中 用 contract 可以查看 ABI （进而获得合约中所有的公共函数），我们查看得知有一个 password() 函数：
 ```shell
cast call 0xA53fCB……078D0 "password()" --rpc-url=https://sepolia-rollup.arbitrum.io/rpc
```

返回了 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000a65746865726e6175743000000000000000000000000000000000000000000000

**cast --to-ascii** 解析一下，是 ethernaut0， cast 提交到前面提到的 authenticate()，需要用私钥签署并发送交易，所以我们要用 cast send ：
 ```shell
cast send 0xA53fCB……078D0 "authenticate(string)" ethernaut0 --rpc-url=https://sepolia-rollup.arbitrum.io/rpc --private-key=0x763842……07602
```
等待消息上链之后，回到 Chrome 页面，点击 Submit Instance 来验证我们的结果：通过。


(当然你也可以用 cast send 来手动提交 XD)
 ```shell
cast send 0xD991431D8b033ddCb84dAD257f4821E9d5b38C33 "submitLevelInstance(address)" 0xA53fCB……078D0 --rpc-url=https://sepolia-rollup.arbitrum.io/rpc --private-key=0x763842……07602
```
