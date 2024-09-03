As we cannot use a signal variable to flag the status whether the giveBool function is called or not, the gasleft can be a symbol.

So we can use the gasleft value to determine the first or second call to giveBool function.

Specifically, as the SLOAD opcode consumes at least 2100 gas, we can use one load operation as the symbol.

```solidity
uint gas = gasleft();
    uint tmp = slot0;
    tmp; // silence warning
    return (gas - gasleft()) >= 2000;
```

Then, we use foundry and create a test function but we need to prank the call as the tx.origin to make through this ctf question.