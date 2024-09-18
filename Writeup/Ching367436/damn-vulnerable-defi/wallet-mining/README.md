## [Wallet Mining](https://www.damnvulnerabledefi.xyz/challenges/wallet-mining/)

> There’s a contract that incentivizes users to deploy Safe wallets, rewarding them with 1 DVT. It integrates with an upgradeable authorization mechanism, only allowing certain deployers (a.k.a. wards) to be paid for specific deployments.
>
> The deployer contract only works with a Safe factory and copy set during deployment. It looks like the [Safe singleton factory](https://github.com/safe-global/safe-singleton-factory) is already deployed.
>
> The team transferred 20 million DVT tokens to a user at `0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b`, where her plain 1-of-1 Safe was supposed to land. But they lost the nonce they should use for deployment.
>
> To make matters worse, there’s been rumours of a vulnerability in the system. The team’s freaked out. Nobody knows what to do, let alone the user. She granted you access to her private key.
>
> You must save all funds before it’s too late!
>
> Recover all tokens from the wallet deployer contract and send them to the corresponding ward. Also save and return all user’s funds.
>
> In a single transaction.



### Analysis

#### `AuthorizerUpgradeable` is vulnerable to being reinitialized

The setup script first deployed an AuthorizerFactory, and used it to deploy the authorizer contract.

```solidity
function setUp() public {
  // [...]
  aims[0] = USER_DEPOSIT_ADDRESS;
  AuthorizerFactory authorizerFactory = new AuthorizerFactory();
  authorizer = AuthorizerUpgradeable(authorizerFactory.deployWithProxy(wards, aims, upgrader));
  // [...]
}
```

Note that the `TransparentProxy(payable(authorizer)).setUpgrader(upgrader)` line will not only overwrite the `TransparentProxy.upgrader` but also overwrite the `AuthorizerUpgradeable.needsInit`, since they both use the first storage slot, making `AuthorizerUpgradeable` uninitialized again.

```solidity
contract AuthorizerFactory {
  function deployWithProxy(address[] memory wards, address[] memory aims, address upgrader)
    external
    returns (address authorizer)
  {
    authorizer = address(
      new TransparentProxy( // proxy
        address(new AuthorizerUpgradeable()), // implementation
        abi.encodeCall(AuthorizerUpgradeable.init, (wards, aims)) // init data
      )
    );
    assert(AuthorizerUpgradeable(authorizer).needsInit() == 0); // invariant
    TransparentProxy(payable(authorizer)).setUpgrader(upgrader);
  }
}
contract TransparentProxy is ERC1967Proxy {
  address public upgrader = msg.sender;
  function setUpgrader(address who) external {
    require(msg.sender == ERC1967Utils.getAdmin(), "!admin");
    upgrader = who;
  }
  // [...]
}
contract AuthorizerUpgradeable {
  uint256 public needsInit = 1;
  // [...]
  function init(address[] memory _wards, address[] memory _aims) external {
    require(needsInit != 0, "cannot init");
    for (uint256 i = 0; i < _wards.length; i++) {
      _rely(_wards[i], _aims[i]);
    }
    needsInit = 0;
  }
  // [...]
}
```

#### Calculate the nonce of the `USER_DEPOSIT_ADDRESS`

The ramining part of the set up script set up a `WalletDeployer`, which might be used to deploy wallet like the `USER_DEPOSIT_ADDRESS` one.

```solidity
function setUp() public {
	// [...]
  token.transfer(USER_DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

  // [...]
  // Deploy wallet deployer
  walletDeployer = new WalletDeployer(address(token), address(proxyFactory), address(singletonCopy));

  // Set authorizer in wallet deployer
  walletDeployer.rule(address(authorizer));

  // Fund wallet deployer with tokens
  initialWalletDeployerTokenBalance = walletDeployer.pay();
  token.transfer(address(walletDeployer), initialWalletDeployerTokenBalance);

  vm.stopPrank();
}
```

The `WalletDeployer.drop` is where the wallet is deployed. We can trace into it to know how the nonce is used, and thus recover the nonce in the problem description. Let's investigate `cook.createProxyWithNonce`

```solidity
contract WalletDeployer {
    // [...]
    function drop(address aim, bytes memory wat, uint256 num) external returns (bool) {
        if (mom != address(0) && !can(msg.sender, aim)) {
            return false;
        }

        if (address(cook.createProxyWithNonce(cpy, wat, num)) != aim) {
            return false;
        }

        if (IERC20(gem).balanceOf(address(this)) >= pay) {
            IERC20(gem).transfer(msg.sender, pay);
        }
        return true;
    }
    // [...]
}
```

`cook.createProxyWithNonce` uses create2 to deploy the contract. Therefore, we know how to try all possible nonces util we get the `USER_DEPOSIT_ADDRESS`.

```solidity
contract SafeProxyFactory {
  // [...]
  /**
   * @notice Deploys a new proxy with `_singleton` singleton and `saltNonce` salt. Optionally executes an initializer call to a new proxy.
   * @param _singleton Address of singleton contract. Must be deployed at the time of execution.
   * @param initializer Payload for a message call to be sent to a new proxy contract.
   * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
   */
  function createProxyWithNonce(address _singleton, bytes memory initializer, uint256 saltNonce) public returns (SafeProxy proxy) {
    // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
    bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
    proxy = deployProxy(_singleton, initializer, salt);
    emit ProxyCreation(proxy, _singleton);
  }
  // [...]
  /**
   * @notice Internal method to create a new proxy contract using CREATE2. Optionally executes an initializer call to a new proxy.
   * @param _singleton Address of singleton contract. Must be deployed at the time of execution.
   * @param initializer (Optional) Payload for a message call to be sent to a new proxy contract.
   * @param salt Create2 salt to use for calculating the address of the new proxy contract.
   * @return proxy Address of the new proxy contract.
   */
  function deployProxy(address _singleton, bytes memory initializer, bytes32 salt) internal returns (SafeProxy proxy) {
    require(isContract(_singleton), "Singleton contract not deployed");

    bytes memory deploymentData = abi.encodePacked(type(SafeProxy).creationCode, uint256(uint160(_singleton)));
    // solhint-disable-next-line no-inline-assembly
    assembly {
      proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
    }
    require(address(proxy) != address(0), "Create2 call failed");

    if (initializer.length > 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        if eq(call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) {
          revert(0, 0)
        }
      }
    }
  }
  // [...]
}
```

### Solution
// Not completed yet
See [WalletMining.t.sol](./WalletMining.t.sol#L127).