## [Puppet](https://www.damnvulnerabledefi.xyz/challenges/puppet/)

> There’s a lending pool where users can borrow Damn Valuable Tokens (DVTs). To do so, they first need to deposit twice the borrow amount in ETH as collateral. The pool currently has 100000 DVTs in liquidity.
>
> There’s a DVT market opened in an old Uniswap v1 exchange, currently with 10 ETH and 10 DVT in liquidity.
>
> Pass the challenge by saving all tokens from the lending pool, then depositing them into the designated recovery account. You start with 25 ETH and 1000 DVTs in balance.



### Analysis

When we borrow DVT from the lending pool, we need to deposit twice the value of the DVT amount we borrow in ETH. Below is how this amount is calculated, which we might be able to control. If we could make `calculateDepositRequired()` return 0, then we could borrow all of the DVT tokens from the pool for free. To do so, we need to make `uniswapPair.balance` smaller and `token.balanceOf(uniswapPair)` larger, which can be achieved by selling DVT tokens to Uniswap.

```solidity
contract PuppetPool is ReentrancyGuard {
    // [...]
    function calculateDepositRequired(uint256 amount) public view returns (uint256) {
        return amount * _computeOraclePrice() * DEPOSIT_FACTOR / 10 ** 18;
    }
    function _computeOraclePrice() private view returns (uint256) {
        // calculates the price of the token in wei according to Uniswap pair
        return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
    }
}
```

#### Selling DVT token to Uniswap

We can use the `IUniswapV1Exchange.tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline)` function to sell our DVT for ETH.

```solidity
interface IUniswapV1Exchange {
  // [...]
	function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline)
  // [...]
}
```


### Solution
See [Puppet.t.sol](./Puppet.t.sol#L94).