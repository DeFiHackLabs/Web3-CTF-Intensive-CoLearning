## [Naive Receiver](https://www.damnvulnerabledefi.xyz/challenges/naive-receiver/)

> There’s a pool with 1000 ETH in balance, offering flash loans. It has a fixed fee of 1 ETH.
>
> A user has deployed a contract with 10 ETH in balance. It’s capable of interacting with the pool and receiving flash loans of ETH.
>
> Take all ETH out of the user’s contract. If possible, in a single transaction.

```javascript
function _isSolved() private view {
    // Player must have executed two or less transactions
    assertLe(vm.getNonce(player), 2);

    // The flashloan receiver contract has been emptied
    assertEq(weth.balanceOf(address(receiver)), 0, "Unexpected balance in receiver contract");

    // Pool is empty too
    assertEq(weth.balanceOf(address(pool)), 0, "Unexpected balance in pool");

    // All funds sent to recovery account
    assertEq(weth.balanceOf(recovery), WETH_IN_POOL + WETH_IN_RECEIVER, "Not enough WETH in recovery account");
}
```



### Analysis

In this challenge, we need to move all of the WETH in the `FlashLoanReceiver` and `NaiveReceiverPool` contracts to the `recovery` address.

#### Drain the `FlashLoanReceiver` Contract
The `FlashLoanReceiver.onFlashLoan` function first checks whether the caller is the `NaiveReceiverPool`. If not, the function will `revert InvalidCaller()`. It also checks whether the `token` is WETH. It is important to note that there are no other checks in place. Therefore, we can simply call `NaiveReceiverPool.flashLoan(FlashLoanReceiver,)` ten times. This will drain all the WETH from the `FlashLoanReceiver` to the `NaiveReceiverPool`, as it will pay the fee to the `NaiveReceiverPool` every time the `FlashLoanReceiver.onFlashLoan` is invoked.

```solidity
contract NaiveReceiverPool is Multicall, IERC3156FlashLender {    
    // [...]
    function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        assembly {
            // gas savings
            if iszero(eq(sload(pool.slot), caller())) {
                mstore(0x00, 0x48f5c3ed)
                revert(0x1c, 0x04)
            }
        }

        if (token != address(NaiveReceiverPool(pool).weth())) revert NaiveReceiverPool.UnsupportedCurrency();

        uint256 amountToBeRepaid;
        unchecked {
            amountToBeRepaid = amount + fee;
        }

        _executeActionDuringFlashLoan();

        // Return funds to pool
        WETH(payable(token)).approve(pool, amountToBeRepaid);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
```

#### Drain the `NaiveReceiverPool` Contract
Next, we need to move all of the WETH from the `NaiveReceiverPool` to the `recovery` address. It is important to note that the `NaiveReceiverPool.withdraw` uses `_msgSender` to determine the caller. If the caller is the `trustedForwarder`, the function will use the last 20 bytes of the `msg.data` as the sender ([ERC2771](https://docs.openzeppelin.com/contracts/5.x/api/metatx)). The `NaiveReceiverPool` also uses multicall, which [when used with ERC2771, will allow us to fake the sender address](https://blog.openzeppelin.com/arbitrary-address-spoofing-vulnerability-erc2771context-multicall-public-disclosure). Therefore, we can withdraw all the WETH as the `_feeReceiver` from the `NaiveReceiverPool` to the `recovery` address.

```solidity
contract NaiveReceiverPool is Multicall, IERC3156FlashLender {
    // [...]
    function withdraw(uint256 amount, address payable receiver) external {
        // Reduce deposits
        deposits[_msgSender()] -= amount;
        totalDeposits -= amount;

        // Transfer ETH to designated receiver
        weth.transfer(receiver, amount);
    }
    // [...]
    function _msgSender() internal view override returns (address) {
        if (msg.sender == trustedForwarder && msg.data.length >= 20) {
            return address(bytes20(msg.data[msg.data.length - 20:]));
        } else {
            return super._msgSender();
        }
    }
}
```

### Solution
See [NaiveReceiver.t.sol](./NaiveReceiver.t.sol#L81)
