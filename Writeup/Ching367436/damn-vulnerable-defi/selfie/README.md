## [Selfie](https://www.damnvulnerabledefi.xyz/challenges/selfie/)

> A new lending pool has launched! It’s now offering flash loans of DVT tokens. It even includes a fancy governance mechanism to control it.
>
> What could go wrong, right ?
>
> You start with no DVT tokens in balance, and the pool has 1.5 million at risk.
>
> Rescue all funds from the pool and deposit them into the designated recovery account.

### Analysis

To solve this challenge, we need to transfer all of the tokens from the `pool` to the `recovery` address.

```solidity
function _isSolved() private view {
    // Player has taken all tokens from the pool
    assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
    assertEq(token.balanceOf(recovery), TOKENS_IN_POOL, "Not enough tokens in recovery account");
}
```

To drain the tokens from the `pool`, we first need to identify all the locations where transfers occur in the pool contract. In our case, these are `SelfiePool.emergencyExit` and `SelfiePool.flashLoan`. The `emergencyExit` seems more promising as it does not require us to pay back the tokens. Let investigate it! 

```solidity
contract SelfiePool is IERC3156FlashLender, ReentrancyGuard {
	// [...]
  function flashLoan(IERC3156FlashBorrower _receiver, address _token, uint256 _amount, bytes calldata _data)
      external
      nonReentrant
      returns (bool)
  {
      // [...]
      token.transfer(address(_receiver), _amount);
      if (_receiver.onFlashLoan(msg.sender, _token, _amount, 0, _data) != CALLBACK_SUCCESS) {
          revert CallbackFailed();
      }

      if (!token.transferFrom(address(_receiver), address(this), _amount)) {
          revert RepayFailed();
      }

      return true;
  }

  function emergencyExit(address receiver) external onlyGovernance {
      uint256 amount = token.balanceOf(address(this));
      token.transfer(receiver, amount);

      emit EmergencyExit(receiver, amount);
  }
}
```

The `emergencyExit` function uses the `onlyGovernance` modifier, which only allows it to be invoked it via the `governance` contract.

```solidity
modifier onlyGovernance() {
    if (msg.sender != address(governance)) {
        revert CallerNotGovernance();
    }
    _;
}
```

#### `SimpleGovernance`

##### `SimpleGovernance.executeAction`

The `SimpleGovernance.executeAction` is interesting because it invokes `actionToExecute.target.functionCallWithValue` at its conclusion, which might allow us to invoke other contracts on behalf of the `governance` contract. We can control `actionToExecute = _actions[actionId]` by using the `SimpleGovernance.queueAction` function. Let's investigate it.

```solidity
contract SimpleGovernance is ISimpleGovernance {
  // [...]
  function executeAction(uint256 actionId) external payable returns (bytes memory) {
      if (!_canBeExecuted(actionId)) {
          revert CannotExecute(actionId);
      }

      GovernanceAction storage actionToExecute = _actions[actionId];
      actionToExecute.executedAt = uint64(block.timestamp);

      emit ActionExecuted(actionId, msg.sender);

      return actionToExecute.target.functionCallWithValue(actionToExecute.data, actionToExecute.value);
  }
  // [...]
  /**
   * @dev an action can only be executed if:
   * 1) it's never been executed before and
   * 2) enough time has passed since it was first proposed
   */
  function _canBeExecuted(uint256 actionId) private view returns (bool) {
      GovernanceAction memory actionToExecute = _actions[actionId];

      if (actionToExecute.proposedAt == 0) return false;

      uint64 timeDelta;
      unchecked {
          timeDelta = uint64(block.timestamp) - actionToExecute.proposedAt;
      }

      return actionToExecute.executedAt == 0 && timeDelta >= ACTION_DELAY_IN_SECONDS;
  }
  // [...]
}
```

##### `SimpleGovernance.queueAction`

To control `_actions[actionId]`, we need to pass the `if (!_hasEnoughVotes(msg.sender))` condition at the beginning of the `queueAction` function.

```solidity
contract SimpleGovernance is ISimpleGovernance {
	// [...]
  function queueAction(address target, uint128 value, bytes calldata data) external returns (uint256 actionId) {
      if (!_hasEnoughVotes(msg.sender)) {
          revert NotEnoughVotes(msg.sender);
      }
      // [...]
      actionId = _actionCounter;

      _actions[actionId] = GovernanceAction({
          target: target,
          value: value,
          proposedAt: uint64(block.timestamp),
          executedAt: 0,
          data: data
      });

      unchecked {
          _actionCounter++;
      }

      emit ActionQueued(actionId, msg.sender);
  }
  // [...]
  function _hasEnoughVotes(address who) private view returns (bool) {
      uint256 balance = _votingToken.getVotes(who);
      uint256 halfTotalSupply = _votingToken.totalSupply() / 2;
      return balance > halfTotalSupply;
  }
}
```

We can use `SelfiePool.flashLoan` to acquire enough votes to satisfy the check. Note that the token balance does not account for voting power as seen in the code comment below. Therefore, we need to delegate the votes to ourselves first.

```solidity
/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^208^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: This contract does not provide interface compatibility with Compound's COMP token.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 */
abstract contract ERC20Votes is ERC20, Votes {
  // [...]
}
```

We have everything required, so the challenge is essentially resolved.

### Solution
See [Selfie.t.sol](./Selfie.t.sol#L66).