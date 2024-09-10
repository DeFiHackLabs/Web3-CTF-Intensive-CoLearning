## 题目 [Wallet Mining](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/wallet-mining)

有一个合约会激励用户部署 Safe 钱包，并奖励他们 1 个 DVT 代币。该合约与一个可升级的授权机制集成在一起，只允许特定的部署者（即 “wards”）因特定的部署而获得报酬。  

该部署者合约只能与部署期间设定的 Safe 工厂和副本配合使用。看起来 [Safe singleton factory](https://github.com/safe-global/safe-singleton-factory) 已经被部署好了。  

团队将 2000 万个 DVT 代币转移给了地址 0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b 的用户，这个地址本应是她的普通 1-of-1 Safe 钱包所在的地方。但他们丢失了用于部署的 nonce 值。  

更糟的是，有传言说系统存在一个漏洞。团队因此非常紧张，没有人知道该怎么做，包括那个用户。她已经授予你访问她私钥的权限。  

你必须在为时已晚之前拯救所有资金！  

需要从钱包部署者合约中回收所有代币并将其发送到对应的 ward。同时，保存并返还所有用户的资金。  

所有这些操作必须在一个交易中完成。  

**要求：**  
1. USER_DEPOSIT_ADDRESS(0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b) 该地址必须有代码。
2. USER_DEPOSIT_ADDRESS 该地址余额清空。
3. 用来奖励 1 个 DVT 的合约余额清空。
4. user 账户，即给你私钥的那个账户，交易 nonce 为 0。
5. 你的交易 nonce 只为 1。
6. 你帮 user 账户找回了所有的代币，即 user 的余额为 2000 万 DVT。
7. wards 账户余额为 1 个 DVT。

总的来说，就是玩家（攻击者）需要从 USER_DEPOSIT_ADDRESS 地址中提取存款，并将这些代币转移到用户（user）账户，同时将支付一定数量的代币给 ward 地址。  

本题暂时跳过。