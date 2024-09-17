## [Puppet V3](https://www.damnvulnerabledefi.xyz/challenges/puppet-v3/)

> Bear or bull market, true DeFi devs keep building. Remember that lending pool you helped? A new version is out.
>
>They’re now using Uniswap V3 as an oracle. That’s right, no longer using spot prices! This time the pool queries the time-weighted average price of the asset, with all the recommended libraries.
>
>The Uniswap market has 100 WETH and 100 DVT in liquidity. The lending pool has a million DVT tokens.
>
>Starting with 1 ETH and some DVT, you must save all from the vulnerable lending pool. Don’t forget to send them to the designated recovery account.

### Analysis

This challenge is basically the same as the [Puppet V2](https://www.damnvulnerabledefi.xyz/challenges/puppet-v2/) challenge, except for the Oracle function. We can still manipulate the oracle price. Except it now uses a time weighted average price (TWAP) from Uniswap V3. Therefore, we need to wait a while for the price to drop before borrowing DVT from the pool with minimal collateral.

```solidity
contract PuppetV3Pool {
  // [...]
  function calculateDepositOfWETHRequired(uint256 amount) public view returns (uint256) {
    uint256 quote = _getOracleQuote(_toUint128(amount));
    return quote * DEPOSIT_FACTOR;
  }

  function _getOracleQuote(uint128 amount) private view returns (uint256) {
    (int24 arithmeticMeanTick,) = OracleLibrary.consult({pool: address(uniswapV3Pool), secondsAgo: TWAP_PERIOD});
    return OracleLibrary.getQuoteAtTick({
        tick: arithmeticMeanTick,
        baseAmount: amount,
        baseToken: address(token),
        quoteToken: address(weth)
    });
  }
  // [...]
}
```

### Solution
Full solution can be found in [PuppetV3.t.sol](./PuppetV3.t.sol#L121).
```solidity
function test_puppetV3() public checkSolvedByPlayer {
  // [...]
  puppetV3Solution.swapDVTForWETH();
  skip(114);
  puppetV3Solution.borrowDVTFromPool();
  puppetV3Solution.transferTokenToRecovery();
}
```
