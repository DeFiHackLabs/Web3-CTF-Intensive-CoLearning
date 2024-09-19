### HarryRiddle

**Hello World**

- Description: To solve this challenge, we just send minus `13.37 ether` to `TARGET` contract.

```javascript
    function isSolved() external view returns (bool) {
@>      return TARGET.balance > STARTING_BALANCE + 13.37 ether;
    }
```

**Grains of sand**

- Description: To solve this challenge, we will need to take token out of `TOKENSTORES` contract.

```javascript
    function isSolved() external view returns (bool) {
@>      return INITIAL_BALANCE - TOKEN.balanceOf(TOKENSTORE) >= 11111e8;
    }
```

`0xC937f5027D47250Fa2Df8CbF21F6F88E98817845` contract belongs to `XGR` token on mainnet. We will explore the bugs in the transactions list.

In the Token contract:

```javascript
    uint256 public transactionFeeRate   = 20; // 0.02 %
    uint256 public transactionFeeRateM  = 1e3; // 1000
    uint256 public transactionFeeMin    =   2000000; // 0.2 XGR
    uint256 public transactionFeeMax    = 200000000; // 2.0 XGR
    function transfer(address to, uint256 amount, bytes extraData) external returns (bool success) {
        _transfer(msg.sender, to, amount, true, extraData);
        return true;
    }
    function _transfer(address from, address to, uint256 amount, bool fee, bytes extraData) internal {
        bool _success;
        uint256 _fee;
        uint256 _payBack;
        uint256 _amount = amount;
        uint256 balance = TokenDB(databaseAddress).balanceOf(from);
        uint256 lockedBalance = TokenDB(databaseAddress).lockedBalances(from);
        balance = safeSub(balance, lockedBalance);
        require( _amount > 0 && balance > 0 );
        require( from != 0x00 && to != 0x00 );
        if( fee ) {
            (_success, _fee) = getTransactionFee(amount);
            require( _success );
            if ( balance == amount ) {
                _amount = safeSub(amount, _fee);
            }
        }
        require( balance >= safeAdd(_amount, _fee) );
        if ( fee ) {
            Burn(from, _fee);
        }
        Transfer(from, to, _amount);
        Transfer2(from, to, _amount, extraData);
        require( TokenDB(databaseAddress).transfer(from, to, _amount, _fee) );
    }
    function getTransactionFee(uint256 value) public constant returns (bool success, uint256 fee) {
        fee = safeMul(value, transactionFeeRate) / transactionFeeRateM / 100;
        if ( fee > transactionFeeMax ) { fee = transactionFeeMax; }
        else if ( fee < transactionFeeMin ) { fee = transactionFeeMin; }
        return (true, fee);
    }
```

Fee calculation is as follows:

```javascript
fee = (value * 20) / 1000 / 100;
transactionFeeMin = 2e8;
transactionFeeMax = 0.2e8;
```

So, the fee is minus `0.2e8` on any transfers.

In order to hit the max transaction fee `2e8`, we'd need the following the amount of tokens:

```javascript
value = (2e8 * 100 * 1000) / 20; = 10000e8
```

With `2e8` transaction fee, we'd need to perform `11111e8 / 2e8 = 5555.5 = 5556` withdrawals of 10,000 tokens. Unless we can buy 55.5 million tokens (not realistic at all), we'll have to resort to abusing the minimum transaction fee of `0.02e8` in some way

- We can now come up with an initial plan:
  - Gain access to token by fulfilling old sell orders using our 1,000 ETH.
  - Withdraw one WEI of token repeatedly from the `TOKENSTORE` contract until we've forced the `TOKENSTORE` contract to pay `11111e8` tokens in fees. We'd then have met the `isSolved()` condition.

However, we should do math again because something was wrong in the doing time. If we continuously withdraw 1 token in order to make the `TOKENSTORE` contract to pay `0.02e8` fee, we'll need to withdraw `11111e8 / 0.02e8 = 555550` times. In my testing, I could withdraw ~ over 1,000 times in a single transaction before running out of gas. At a rate of approximately 8 seconds per transaction, we get:

1,000 withdrawals = `0.02 * 1000 = 20` token every 8 seconds
`11111 / 20 = 555.55` = 556 transactions required
556 transactions \* 8 seconds = 4,448 seconds required = 74 minutes.

Unfortunately, we only have 1440 seconds for the instance provided to us to solve this proble. So, we hope to buy a large enough amount of token from the `TOKENSTORE` contract.
