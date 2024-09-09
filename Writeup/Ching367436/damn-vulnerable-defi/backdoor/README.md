## [Backdoor](https://www.damnvulnerabledefi.xyz/challenges/backdoor/)

> To incentivize the creation of more secure wallets in their team, someone has deployed a registry of Safe wallets. When someone in the team deploys and registers a wallet, they earn 10 DVT tokens.
>
> The registry tightly integrates with the legitimate Safe Proxy Factory. It includes strict safety checks.
>
> Currently there are four people registered as beneficiaries: Alice, Bob, Charlie and David. The registry has 40 DVT tokens in balance to be distributed among them.
>
> Uncover the vulnerability in the registry, rescue all funds, and deposit them into the designated recovery account. In a single transaction.



### Analysis

The only function in the `WalletRegistry` contract that we can invoke is `WalletRegistry.proxyCreated`. Let's investigate it.

#### `WalletRegistry.proxyCreated`

`WalletRegistry.proxyCreated` requires that `msg.sender` be `walletFactory`. Let's investigate it.

```solidity
function proxyCreated(SafeProxy proxy, address singleton, bytes calldata initializer, uint256) external override {
  // [...]
  if (msg.sender != walletFactory) {
    revert CallerNotFactory();
  }
  // [...]
}
```

#### `SafeProxyFactory`

There is only one place that can invoke `WalletRegistry.proxyCreated` : `SafeProxyFactory.createProxyWithCallback`. If we dig further into `SafeProxyFactory.createProxyWithCallback`, we can find that it creates a proxy contract that always delegates calls to the `_singleton`.

Let's return to `WalletRegistry.proxyCreated`.

```solidity
contract SafeProxyFactory {
  // [...]
  /**
   * @notice Deploy a new proxy with `_singleton` singleton and `saltNonce` salt.
   *         Optionally executes an initializer call to a new proxy and calls a specified callback address `callback`.
   * @param _singleton Address of singleton contract. Must be deployed at the time of execution.
   * @param initializer Payload for a message call to be sent to a new proxy contract.
   * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
   * @param callback Callback that will be invoked after the new proxy contract has been successfully deployed and initialized.
   */
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
  // [...]
}
```

#### `WalletRegistry.proxyCreated`

`WalletRegistry.proxyCreated` also requires that `singleton != singletonCopy`, so the `_singleton` we pass to the `SafeProxyFactory.createProxyWithCallback` should be `singletonCopy`. As a result, the deployed wallet can only be `Safe` (safe-smart-account/contracts/Safe.sol). Next, it ensures that the initial call data was a call to `Safe::setup`, but it does not check the arguments. It then checks some conditions on the `safe`. Finally, it transfers the tokens to the safe. Our goal is to transfer those tokens to the `recovery` address.

Let's check the `Safe::setup` function.

```solidity
function proxyCreated(SafeProxy proxy, address singleton, bytes calldata initializer, uint256) external override {
  // [...]
  if (singleton != singletonCopy) {
    revert FakeSingletonCopy();
  }
  
  // Ensure initial calldata was a call to `Safe::setup`
  if (bytes4(initializer[:4]) != Safe.setup.selector) {
    revert InvalidInitialization();
  }
  
  // Ensure wallet initialization is the expected
  uint256 threshold = Safe(walletAddress).getThreshold();
  if (threshold != EXPECTED_THRESHOLD) {
    revert InvalidThreshold(threshold);
  }

  // Ensure the owner is a registered beneficiary
  address[] memory owners = Safe(walletAddress).getOwners();
  if (owners.length != EXPECTED_OWNERS_COUNT) {
    revert InvalidOwnersCount(owners.length);
  }

  // Ensure the owner is a registered beneficiary
  address walletOwner;
  unchecked {
    walletOwner = owners[0];
  }
  if (!beneficiaries[walletOwner]) {
    revert OwnerIsNotABeneficiary();
  }

  address fallbackManager = _getFallbackManager(walletAddress);
  if (fallbackManager != address(0)) {
    revert InvalidFallbackManager(fallbackManager);
  }

  // Remove owner as beneficiary
  beneficiaries[walletOwner] = false;

  // Register the wallet under the owner's address
  wallets[walletOwner] = walletAddress;

  // Pay tokens to the newly created wallet
  SafeTransferLib.safeTransfer(address(token), walletAddress, PAYMENT_AMOUNT);
}
```

#### `Safe`

Referring to the comment on the `Safe::setup` function, it has arguments related to payment! It allows us to send the token from the safe when calling `setup`. Unfortunately, at the time of calling `setup`, the safe does not have any token yet. Fortunately, we also have a `fallbackHandler` argument to execute any code in the context of the `safe`. We can approve the token first, and transfer it later when it has tokens.

```solidity
contract Safe {
  // [...]
  /**
   * @notice Sets an initial storage of the Safe contract.
   * @dev This method can only be called once.
   *      If a proxy was created without setting up, anyone can call setup and claim the proxy.
   * @param _owners List of Safe owners.
   * @param _threshold Number of required confirmations for a Safe transaction.
   * @param to Contract address for optional delegate call.
   * @param data Data payload for optional delegate call.
   * @param fallbackHandler Handler for fallback calls to this contract
   * @param paymentToken Token that should be used for the payment (0 is ETH)
   * @param payment Value that should be paid
   * @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
   */
  function setup(
    address[] calldata _owners,
    uint256 _threshold,
    address to,
    bytes calldata data,
    address fallbackHandler,
    address paymentToken,
    uint256 payment,
    address payable paymentReceiver
  ) external {
    // setupOwners checks if the Threshold is already set, therefore preventing that this method is called twice
    setupOwners(_owners, _threshold);
    if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);
    // As setupOwners can only be called if the contract has not been initialized we don't need a check for setupModules
    setupModules(to, data);

    if (payment > 0) {
        // To avoid running into issues with EIP-170 we reuse the handlePayment function (to avoid adjusting code of that has been verified we do not adjust the method itself)
        // baseGas = 0, gasPrice = 1 and gas = payment => amount = (payment + 0) * 1 = payment
        handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
    }
    emit SafeSetup(msg.sender, _owners, _threshold, to, fallbackHandler);
  }
  // [...]
}
```

### Solution
See [Backdoor.t.sol](./Backdoor.t.sol#L74).