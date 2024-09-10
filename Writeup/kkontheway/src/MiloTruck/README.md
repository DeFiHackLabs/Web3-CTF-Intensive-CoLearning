## Escrow

## GreyHats-Dollar
Self Transfer in `transferFrom()`

```solidity
function transferFrom(address from, address to, uint256 amount) public update returns (bool) {
        if (from != msg.sender) allowance[from][msg.sender] -= amount;

        uint256 _shares = _GHDToShares(amount, conversionRate, false);
        uint256 fromShares = shares[from] - _shares;
        uint256 toShares = shares[to] + _shares;

        require(_sharesToGHD(fromShares, conversionRate, false) < balanceOf(from), "amount too small");
        require(_sharesToGHD(toShares, conversionRate, false) > balanceOf(to), "amount too small");

        shares[from] = fromShares;
        shares[to] = toShares;

        emit Transfer(from, to, amount);

        return true;
    }
```

## SimpleAMM
在初始化后，各个合约的状态是：

| Vault             |              |
| ----------------- | ------------ |
| totalAssets(Grey) | 2000e18      |
| totalSupply       | 1000e18      |
| sharePrice        | 2:1(Grey:SV) |

| AMM      |         |
| -------- | ------- |
| k        | 2000e18 |
| reserveX | 1000e18 |
| reserveY | 2000e18 |

因为amm有flashloan，所以我们可以先flashloan出来1000e18的sv，然后用这1000e18的sv从Vaule中提取出2000e18的grey，在存入1000e18的grey这时候状态就变成了

| Vault             |              |
| ----------------- | ------------ |
| totalAssets(Grey) | 1000e18      |
| totalSupply       | 1000e18      |
| sharePrice        | 1:1(Grey:SV) |

由于amm的价格依赖于vault，所以这时候我们不需要任何的amountIn就可以换出1000e18的grey，从而完成挑战