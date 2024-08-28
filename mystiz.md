---
timezone: Asia/Taipei
---

# Mystiz

1. 自我介紹

Software Engineer @google. CTF since 2017. Blog [here](https://mystiz.hk/about-me/).

2. 你認為你會完成本次殘酷學習嗎？

Can't say yes, but I hope this could get me motivated.

## Notes

<!-- Content_START -->

### 2024.08.28

1. 設定 Foundry 環境。https://book.getfoundry.sh/getting-started/installation
2. 把 Damn Vulnerable DeFi、EthTaipei CTF 2023 跟 MetaTrust CTF 2023 的題目先打包下來備用。
    * 把 EthTaipei CTF 2023 的答案刪掉。
    * MetaTrust CTF 2023 repo 要轉換成 Foundry 的模式，到解題的時候再把它們轉換過去。

目標：完成 Damn Vulnerable DeFi + EthTaipei CTF 2023 及 MetaTrust CTF 2023。

### 2024.08.29

Progress

* Damn Vulnerable DeFi (1/18)
* EthTaipei CTF 2023 (0/5)
* MetaTrust CTF 2023 (0/22)

#### Tools and references

##### ERC-3156: Flash Loans

Reference: https://eips.ethereum.org/EIPS/eip-3156

> A flash loan is a smart contract transaction in which a lender smart contract lends assets to a borrower smart contract with the condition that the assets are returned, plus an optional fee, before the end of the transaction.

##### Foundry debug tricks

```solidity
pragma solidity =0.8.25;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156.sol";

contract ExploitContract is IERC3156FlashBorrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        // Take the money from receiver
        

        return keccak256("IERC3156FlashBorrower.onFlashLoan");
    }
}
```

```bash
# We can use -vvvv to make the log super-verbose
forge test --match-test test_unstoppable -vvvv
```

This is what it looks when `vault.flashLoan(exploit, address(token), 1e18, bytes("00"));` is called, when my exploit contract is given above.

![](Writeup/mystiz/images/20240829-dvd-unstoppable-1.png)

<!-- Content_END -->

#### Damn Vulnerable DeFi: Unstoppable

The goal of the challenge is to pause the vault. One way to trigger is to make the `vault.flashLoan` raise an exception -- thus the vault will be stopped when `isSolved` is called.

```solidity
try vault.flashLoan(this, asset, amount, bytes("")) { /* omitted */ } catch { /* pauses the vault here! */ }
// called in src/unstoppable/UnstoppableMonitor.sol:checkFlashLoan(100e18) (line 41)
// called in test/unstoppable/Unstoppable.t.sol:_isSolved() (line 106)
```

To make this happen, we can make `convertToShares(totalSupply) != balanceBefore`. In that's the case, the transaction will be reverted -- and thus raising an exception. We can simply transfer 1 DVT to the vault.
