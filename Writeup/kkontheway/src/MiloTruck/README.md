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