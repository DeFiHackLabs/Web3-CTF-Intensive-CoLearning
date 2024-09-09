## [Climber](https://www.damnvulnerabledefi.xyz/challenges/climber/)

> There’s a secure vault contract guarding 10 million DVT tokens. The vault is upgradeable, following the [UUPS pattern](https://eips.ethereum.org/EIPS/eip-1822).
>
> The owner of the vault is a timelock contract. It can withdraw a limited amount of tokens every 15 days.
>
> On the vault there’s an additional role with powers to sweep all tokens in case of an emergency.
>
> On the timelock, only an account with a “Proposer” role can schedule actions that can be executed 1 hour later.
>
> You must rescue all tokens from the vault and deposit them into the designated recovery account.

```solidity
function _isSolved() private view {
  assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
  assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
}
```

 ### Analysis

We need to transfer the DVT tokens from the vault to recovery. We start by looking for all the locations where we can perform the token transfer. There are three potential locations: `ClimberVault::withdraw`, `ClimberVault::sweepFunds`, and `UUPSUpgradeable::upgradeToAndCall` (which can upgrade the implementation directly). The amount that the `ClimberVault::withdraw` function can withdraw is too small, and it has an unmodifiable time lock. The `ClimberVault::sweepFunds` function looks more practical. It has the `onlySweeper` modifier, but we cannot modify the sweeper, so it's useless. Let's investigate the `UUPSUpgradeable::upgradeToAndCall` function.
```solidity
contract ClimberVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  // [...]
  // Allows the owner to send a limited amount of tokens to a recipient every now and then
	function withdraw(address token, address recipient, uint256 amount) external onlyOwner {
    if (amount > WITHDRAWAL_LIMIT) {
      revert InvalidWithdrawalAmount();
    }

    if (block.timestamp <= _lastWithdrawalTimestamp + WAITING_PERIOD) {
      revert InvalidWithdrawalTime();
    }

    _updateLastWithdrawalTimestamp(block.timestamp);

    SafeTransferLib.safeTransfer(token, recipient, amount);
  }

  // Allows trusted sweeper account to retrieve any tokens
  function sweepFunds(address token) external onlySweeper {
    SafeTransferLib.safeTransfer(token, _sweeper, IERC20(token).balanceOf(address(this)));
  }
}
```

#### `UUPSUpgradeable::upgradeToAndCall`

The `UUPSUpgradeable::upgradeToAndCall` function requires `_authorizeUpgrade`, and only the owner can pass this check. We can see from the `initialize` function that the owner is `ClimberTimelock`. Let us investigate the `ClimberTimelock` contract.
```solidity
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable {
  // [...]
  function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
    _authorizeUpgrade(newImplementation); // See below `ClimberVault::_authorizeUpgrade`
    _upgradeToAndCallUUPS(newImplementation, data);
  }
  // [...]
}
contract ClimberVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  // [...]
  function initialize(address admin, address proposer, address sweeper) external initializer {
    // [...]
    transferOwnership(address(new ClimberTimelock(admin, proposer)));
    // [...]
	}
  // [...]
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
```

#### `ClimberTimelock`

The `ClimberTimelock::execute` function calls `targets[i].functionCallWithValue(dataElements[i], values[i])`, and `targets`, `dataElements`, and `values` are all controllable by us! However, it will also check if `getOperationState(id) != OperationState.ReadyForExecution`. Let us investigate whether we can bypass this check.

```solidity
contract ClimberTimelock is ClimberTimelockBase {
  using Address for address;
  // [...]
  function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements, bytes32 salt)
    external payable
  {
    // [...]
    bytes32 id = getOperationId(targets, values, dataElements, salt); // keccak256 hash of the four arguments

    for (uint8 i = 0; i < targets.length; ++i) {
      targets[i].functionCallWithValue(dataElements[i], values[i]);
    }

    if (getOperationState(id) != OperationState.ReadyForExecution) {
      revert NotReadyForExecution(id);
    }

    operations[id].executed = true;
  }
}
```

#### `ClimberTimelockBase::getOperationState`

`ClimberTimelockBase::getOperationState` ensures that the task is scheduled and that a specific time has passed. We can schedule a task using the `ClimberTimelock::schedule` function. Though it has the `onlyRole(PROPOSER_ROLE)` modifier, we can first grant ourselves the admin role using the `grantRole` function. The delay of the time lock can also be modified using the `updateDelay` function. Therefore, we have everything we need to bypass `ClimberTimelock::execute`. We can now assign ourselves as the owner of the `ClimberVault` contract and upgrade it to our own contract.
```solidity
abstract contract ClimberTimelockBase is AccessControl {
  // [...]
  function getOperationState(bytes32 id) public view returns (OperationState state) {
    Operation memory op = operations[id];

    if (op.known) {
      if (op.executed) {
        state = OperationState.Executed;
      } else if (block.timestamp < op.readyAtTimestamp) {
        state = OperationState.Scheduled;
      } else {
        state = OperationState.ReadyForExecution;
      }
    } else {
      state = OperationState.Unknown;
    }
  }

  function getOperationId(
    address[] calldata targets,
    uint256[] calldata values,
    bytes[] calldata dataElements,
    bytes32 salt
  ) public pure returns (bytes32) {
    return keccak256(abi.encode(targets, values, dataElements, salt));
  }
  // [...]
}
contract ClimberTimelock is ClimberTimelockBase {
  // [...]
  constructor(address admin, address proposer) {
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    _setRoleAdmin(PROPOSER_ROLE, ADMIN_ROLE);

    _grantRole(ADMIN_ROLE, admin);
    _grantRole(ADMIN_ROLE, address(this)); // self administration
    // [...]
  }
  // [...]
  function schedule(
      address[] calldata targets,
      uint256[] calldata values,
      bytes[] calldata dataElements,
      bytes32 salt
  ) external onlyRole(PROPOSER_ROLE) {
     // [...]
      bytes32 id = getOperationId(targets, values, dataElements, salt);

      if (getOperationState(id) != OperationState.Unknown) {
          revert OperationAlreadyKnown(id);
      }

      operations[id].readyAtTimestamp = uint64(block.timestamp) + delay;
      operations[id].known = true;
  }
  // [...]
  function updateDelay(uint64 newDelay) external { /* [...] */ }
}
```


### Solution
See [Climber.t.sol](./Climber.t.sol#L89).