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
